<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ---- Users ----
        User::create([
            'name'     => 'Admin POS',
            'email'    => 'admin@pos.com',
            'password' => Hash::make('password'),
            'role'     => 'admin',
        ]);

        User::create([
            'name'     => 'Kasir 1',
            'email'    => 'kasir@pos.com',
            'password' => Hash::make('password'),
            'role'     => 'kasir',
        ]);

        // ---- Categories ----
        $categories = [
            ['name' => 'Makanan', 'icon' => 'restaurant'],
            ['name' => 'Minuman', 'icon' => 'local_cafe'],
            ['name' => 'Snack',   'icon' => 'cookie'],
            ['name' => 'Dessert', 'icon' => 'cake'],
            ['name' => 'Lainnya', 'icon' => 'more_horiz'],
        ];

        foreach ($categories as $cat) {
            Category::create($cat);
        }

        // ---- Products ----
        $products = [
            // Makanan
            ['category_id' => 1, 'name' => 'Nasi Goreng Spesial', 'price' => 25000, 'stock' => 50],
            ['category_id' => 1, 'name' => 'Mie Goreng',          'price' => 20000, 'stock' => 40],
            ['category_id' => 1, 'name' => 'Ayam Bakar',          'price' => 35000, 'stock' => 30],
            ['category_id' => 1, 'name' => 'Nasi Uduk',           'price' => 18000, 'stock' => 60],
            // Minuman
            ['category_id' => 2, 'name' => 'Kopi Susu',           'price' => 15000, 'stock' => 100],
            ['category_id' => 2, 'name' => 'Es Teh Manis',        'price' => 8000,  'stock' => 100],
            ['category_id' => 2, 'name' => 'Jus Jeruk',           'price' => 18000, 'stock' => 50],
            ['category_id' => 2, 'name' => 'Matcha Latte',        'price' => 22000, 'stock' => 80],
            ['category_id' => 2, 'name' => 'Americano',           'price' => 20000, 'stock' => 80],
            // Snack
            ['category_id' => 3, 'name' => 'Kentang Goreng',      'price' => 15000, 'stock' => 45],
            ['category_id' => 3, 'name' => 'Nugget',              'price' => 18000, 'stock' => 40, 'low_stock_threshold' => 3],
            // Dessert
            ['category_id' => 4, 'name' => 'Pudding Coklat',      'price' => 12000, 'stock' => 4, 'low_stock_threshold' => 5],
            ['category_id' => 4, 'name' => 'Es Krim Vanilla',     'price' => 15000, 'stock' => 20],
        ];

        foreach ($products as $p) {
            Product::create(array_merge([
                'description'          => null,
                'image'                => null,
                'is_active'            => true,
                'low_stock_threshold'  => 5,
            ], $p));
        }
    }
}
