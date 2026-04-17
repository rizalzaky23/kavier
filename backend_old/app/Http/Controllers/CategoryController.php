<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(): JsonResponse
    {
        $categories = Category::withCount(['products' => function ($q) {
            $q->where('is_active', true);
        }])
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $categories]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:100|unique:categories,name',
            'icon' => 'nullable|string|max:50',
        ]);

        $category = Category::create($data);

        return response()->json(['message' => 'Kategori berhasil ditambahkan.', 'data' => $category], 201);
    }

    public function update(Request $request, Category $category): JsonResponse
    {
        $data = $request->validate([
            'name'      => 'required|string|max:100|unique:categories,name,' . $category->id,
            'icon'      => 'nullable|string|max:50',
            'is_active' => 'boolean',
        ]);

        $category->update($data);

        return response()->json(['message' => 'Kategori diperbarui.', 'data' => $category]);
    }

    public function destroy(Category $category): JsonResponse
    {
        if ($category->products()->exists()) {
            return response()->json(['message' => 'Tidak bisa menghapus kategori yang memiliki produk.'], 422);
        }

        $category->delete();

        return response()->json(['message' => 'Kategori dihapus.']);
    }
}
