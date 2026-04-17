<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'name',
        'price',
        'stock',
        'image',
        'description',
        'is_active',
        'low_stock_threshold',
    ];

    protected $casts = [
        'price'               => 'decimal:2',
        'stock'               => 'integer',
        'is_active'           => 'boolean',
        'low_stock_threshold' => 'integer',
    ];

    protected $appends = ['image_url', 'is_low_stock'];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function transactionDetails()
    {
        return $this->hasMany(TransactionDetail::class);
    }

    public function getImageUrlAttribute(): string
    {
        if ($this->image) {
            return url('storage/products/' . $this->image);
        }
        return url('images/no-image.png');
    }

    public function getIsLowStockAttribute(): bool
    {
        return $this->stock <= $this->low_stock_threshold;
    }

    public function decrementStock(int $qty): void
    {
        $this->decrement('stock', $qty);
    }
}
