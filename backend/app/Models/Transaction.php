<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'invoice_number',
        'subtotal',
        'tax',
        'discount',
        'total',
        'paid_amount',
        'change_amount',
        'payment_method', // cash | digital
        'notes',
        'status',         // pending | completed | cancelled
    ];

    protected $casts = [
        'subtotal'      => 'decimal:2',
        'tax'           => 'decimal:2',
        'discount'      => 'decimal:2',
        'total'         => 'decimal:2',
        'paid_amount'   => 'decimal:2',
        'change_amount' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function details()
    {
        return $this->hasMany(TransactionDetail::class);
    }

    protected static function booted(): void
    {
        static::creating(function (Transaction $transaction) {
            $transaction->invoice_number = self::generateInvoice();
        });
    }

    private static function generateInvoice(): string
    {
        $prefix = 'INV-' . now()->format('Ymd');
        $last   = self::where('invoice_number', 'like', $prefix . '%')
            ->orderByDesc('id')
            ->first();

        $seq = $last ? ((int) substr($last->invoice_number, -4) + 1) : 1;

        return $prefix . '-' . str_pad($seq, 4, '0', STR_PAD_LEFT);
    }
}
