<?php

namespace App\Exports;

use App\Models\Transaction;
use Maatwebsite\Excel\Concerns\FromQuery;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class TransactionExport implements FromQuery, WithHeadings, WithMapping, ShouldAutoSize, WithStyles, WithTitle, WithColumnFormatting
{
    public function __construct(
        private readonly \Carbon\Carbon $from,
        private readonly \Carbon\Carbon $to
    ) {}

    public function query()
    {
        return Transaction::with(['user:id,name', 'details'])
            ->where('status', 'completed')
            ->whereBetween('created_at', [$this->from, $this->to])
            ->orderByDesc('created_at');
    }

    public function headings(): array
    {
        return [
            'No.',
            'No. Invoice',
            'Tanggal',
            'Kasir',
            'Item',
            'Subtotal (Rp)',
            'Pajak (Rp)',
            'Diskon (Rp)',
            'Total (Rp)',
            'Dibayar (Rp)',
            'Kembalian (Rp)',
            'Metode Bayar',
        ];
    }

    public function map($row): array
    {
        static $no = 0;
        $no++;

        $items = $row->details->map(fn ($d) => "{$d->product_name} x{$d->quantity}")->join(', ');

        return [
            $no,
            $row->invoice_number,
            $row->created_at->format('d/m/Y H:i'),
            $row->user->name ?? '-',
            $items,
            (float) $row->subtotal,
            (float) $row->tax,
            (float) $row->discount,
            (float) $row->total,
            (float) $row->paid_amount,
            (float) $row->change_amount,
            strtoupper($row->payment_method),
        ];
    }

    public function columnFormats(): array
    {
        return [
            'F' => NumberFormat::FORMAT_NUMBER_COMMA_SEPARATED1,
            'G' => NumberFormat::FORMAT_NUMBER_COMMA_SEPARATED1,
            'H' => NumberFormat::FORMAT_NUMBER_COMMA_SEPARATED1,
            'I' => NumberFormat::FORMAT_NUMBER_COMMA_SEPARATED1,
            'J' => NumberFormat::FORMAT_NUMBER_COMMA_SEPARATED1,
            'K' => NumberFormat::FORMAT_NUMBER_COMMA_SEPARATED1,
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => [
                'font' => ['bold' => true, 'color' => ['argb' => 'FFFFFFFF']],
                'fill' => [
                    'fillType'   => Fill::FILL_SOLID,
                    'startColor' => ['argb' => 'FF1565C0'],
                ],
                'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
            ],
        ];
    }

    public function title(): string
    {
        return 'Laporan Transaksi';
    }
}
