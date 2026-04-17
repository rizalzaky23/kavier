<?php

namespace App\Http\Controllers;

use App\Exports\TransactionExport;
use App\Models\Transaction;
use App\Models\TransactionDetail;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;

class ReportController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        $request->validate([
            'period'    => 'nullable|in:daily,weekly,monthly,custom',
            'date_from' => 'nullable|date',
            'date_to'   => 'nullable|date|after_or_equal:date_from',
        ]);

        [$from, $to] = $this->resolveDateRange($request);

        $transactions = Transaction::where('status', 'completed')
            ->whereBetween('created_at', [$from, $to]);

        $summary = [
            'period'         => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
            'total_revenue'  => (float) (clone $transactions)->sum('total'),
            'total_tax'      => (float) (clone $transactions)->sum('tax'),
            'total_discount' => (float) (clone $transactions)->sum('discount'),
            'total_transactions' => (clone $transactions)->count(),
            'by_payment_method' => (clone $transactions)
                ->select('payment_method', DB::raw('COUNT(*) as count'), DB::raw('SUM(total) as revenue'))
                ->groupBy('payment_method')
                ->get(),
        ];

        return response()->json(['data' => $summary]);
    }

    public function topProducts(Request $request): JsonResponse
    {
        [$from, $to] = $this->resolveDateRange($request);

        $products = TransactionDetail::select(
            'product_name',
            DB::raw('SUM(quantity) as total_qty'),
            DB::raw('SUM(subtotal) as total_revenue')
        )
            ->whereHas('transaction', fn ($q) =>
                $q->where('status', 'completed')->whereBetween('created_at', [$from, $to])
            )
            ->groupBy('product_name')
            ->orderByDesc('total_qty')
            ->limit(10)
            ->get();

        return response()->json(['data' => $products]);
    }

    public function dailyChart(Request $request): JsonResponse
    {
        $from = now()->subDays(29)->startOfDay();
        $to   = now()->endOfDay();

        $daily = Transaction::where('status', 'completed')
            ->whereBetween('created_at', [$from, $to])
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(total) as revenue'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy(DB::raw('DATE(created_at)'))
            ->orderBy('date')
            ->get();

        return response()->json(['data' => $daily]);
    }

    public function export(Request $request)
    {
        $request->validate([
            'date_from' => 'nullable|date',
            'date_to'   => 'nullable|date',
        ]);

        [$from, $to] = $this->resolveDateRange($request);

        $filename = 'Laporan_POS_' . $from->format('Ymd') . '_' . $to->format('Ymd') . '.xlsx';

        return Excel::download(new TransactionExport($from, $to), $filename);
    }

    private function resolveDateRange(Request $request): array
    {
        $period = $request->period ?? 'daily';

        return match ($period) {
            'weekly'  => [now()->startOfWeek(),  now()->endOfDay()],
            'monthly' => [now()->startOfMonth(), now()->endOfDay()],
            'custom'  => [
                \Carbon\Carbon::parse($request->date_from)->startOfDay(),
                \Carbon\Carbon::parse($request->date_to)->endOfDay(),
            ],
            default   => [now()->startOfDay(), now()->endOfDay()], // daily
        };
    }
}
