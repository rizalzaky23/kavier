<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transactions = Transaction::with(['user:id,name', 'details'])
            ->when($request->date_from, fn ($q) => $q->whereDate('created_at', '>=', $request->date_from))
            ->when($request->date_to,   fn ($q) => $q->whereDate('created_at', '<=', $request->date_to))
            ->when($request->status,    fn ($q) => $q->where('status', $request->status))
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json(['data' => $transactions]);
    }

    public function show(Transaction $transaction): JsonResponse
    {
        return response()->json([
            'data' => $transaction->load(['user:id,name', 'details.product:id,name,image']),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'items'             => 'required|array|min:1',
            'items.*.product_id'=> 'required|exists:products,id',
            'items.*.quantity'  => 'required|integer|min:1',
            'discount'          => 'nullable|numeric|min:0',
            'paid_amount'       => 'required|numeric|min:0',
            'payment_method'    => 'required|in:cash,digital',
            'notes'             => 'nullable|string|max:500',
            'tax_percentage'    => 'nullable|numeric|min:0|max:100',
        ]);

        DB::beginTransaction();

        try {
            $subtotal    = 0;
            $detailsData = [];

            foreach ($data['items'] as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);

                if ($product->stock < $item['quantity']) {
                    DB::rollBack();
                    return response()->json([
                        'message' => "Stok produk '{$product->name}' tidak cukup. Tersisa: {$product->stock}.",
                    ], 422);
                }

                $lineTotal     = $product->price * $item['quantity'];
                $subtotal     += $lineTotal;

                $detailsData[] = [
                    'product_id'    => $product->id,
                    'product_name'  => $product->name,
                    'product_price' => $product->price,
                    'quantity'      => $item['quantity'],
                    'subtotal'      => $lineTotal,
                ];

                // Kurangi stok
                $product->decrementStock($item['quantity']);
            }

            $taxPct  = $data['tax_percentage'] ?? (float) env('TAX_PERCENTAGE', 0);
            $tax     = round($subtotal * ($taxPct / 100), 2);
            $discount = $data['discount'] ?? 0;
            $total   = $subtotal + $tax - $discount;

            if ($data['paid_amount'] < $total) {
                DB::rollBack();
                return response()->json(['message' => 'Jumlah bayar kurang dari total.'], 422);
            }

            $transaction = Transaction::create([
                'user_id'        => $request->user()->id,
                'subtotal'       => $subtotal,
                'tax'            => $tax,
                'discount'       => $discount,
                'total'          => $total,
                'paid_amount'    => $data['paid_amount'],
                'change_amount'  => $data['paid_amount'] - $total,
                'payment_method' => $data['payment_method'],
                'notes'          => $data['notes'] ?? null,
                'status'         => 'completed',
            ]);

            $transaction->details()->createMany($detailsData);

            DB::commit();

            return response()->json([
                'message' => 'Transaksi berhasil.',
                'data'    => $transaction->load(['user:id,name', 'details']),
            ], 201);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'Terjadi kesalahan: ' . $e->getMessage()], 500);
        }
    }

    public function cancel(Transaction $transaction): JsonResponse
    {
        if ($transaction->status !== 'completed') {
            return response()->json(['message' => 'Transaksi tidak dapat dibatalkan.'], 422);
        }

        DB::beginTransaction();
        try {
            // Kembalikan stok
            foreach ($transaction->details as $detail) {
                if ($detail->product_id) {
                    Product::where('id', $detail->product_id)->increment('stock', $detail->quantity);
                }
            }
            $transaction->update(['status' => 'cancelled']);
            DB::commit();

            return response()->json(['message' => 'Transaksi dibatalkan dan stok dikembalikan.']);
        } catch (\Throwable $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal: ' . $e->getMessage()], 500);
        }
    }
}
