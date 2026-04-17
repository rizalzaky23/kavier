<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Product::with('category')
            ->when($request->search, fn ($q, $s) => $q->where('name', 'like', "%$s%"))
            ->when($request->category_id, fn ($q, $id) => $q->where('category_id', $id))
            ->when($request->is_active !== null, fn ($q) => $q->where('is_active', $request->boolean('is_active')))
            ->orderBy('name');

        if ($request->per_page) {
            $products = $query->paginate($request->integer('per_page', 20));
        } else {
            $products = $query->get();
        }

        return response()->json(['data' => $products]);
    }

    public function show(Product $product): JsonResponse
    {
        return response()->json(['data' => $product->load('category')]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_id'         => 'required|exists:categories,id',
            'name'                => 'required|string|max:255',
            'description'         => 'nullable|string',
            'price'               => 'required|numeric|min:0',
            'stock'               => 'required|integer|min:0',
            'low_stock_threshold' => 'nullable|integer|min:0',
            'image'               => 'nullable|image|mimes:jpeg,png,jpg,webp|max:2048',
            'is_active'           => 'boolean',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('products', 'public');
            $data['image'] = basename($data['image']);
        }

        $product = Product::create($data);

        return response()->json([
            'message' => 'Produk berhasil ditambahkan.',
            'data'    => $product->load('category'),
        ], 201);
    }

    public function update(Request $request, Product $product): JsonResponse
    {
        $data = $request->validate([
            'category_id'         => 'sometimes|exists:categories,id',
            'name'                => 'sometimes|string|max:255',
            'description'         => 'nullable|string',
            'price'               => 'sometimes|numeric|min:0',
            'stock'               => 'sometimes|integer|min:0',
            'low_stock_threshold' => 'nullable|integer|min:0',
            'image'               => 'nullable|image|mimes:jpeg,png,jpg,webp|max:2048',
            'is_active'           => 'boolean',
        ]);

        if ($request->hasFile('image')) {
            // Hapus gambar lama
            if ($product->image) {
                Storage::disk('public')->delete('products/' . $product->image);
            }
            $data['image'] = basename($request->file('image')->store('products', 'public'));
        }

        $product->update($data);

        return response()->json([
            'message' => 'Produk diperbarui.',
            'data'    => $product->load('category'),
        ]);
    }

    public function destroy(Product $product): JsonResponse
    {
        if ($product->image) {
            Storage::disk('public')->delete('products/' . $product->image);
        }

        $product->delete();

        return response()->json(['message' => 'Produk dihapus.']);
    }

    public function lowStock(): JsonResponse
    {
        $products = Product::with('category')
            ->whereColumn('stock', '<=', 'low_stock_threshold')
            ->where('is_active', true)
            ->get();

        return response()->json(['data' => $products]);
    }
}
