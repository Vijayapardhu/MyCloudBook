import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../models/note.dart';
import '../models/page.dart';
import 'storage_service.dart';

/// Export service for PDF generation with actual image embedding
class ExportService {
  final SupabaseClient _client;
  final StorageService _storageService;
  final Dio _dio;
  
  ExportService({
    SupabaseClient? client,
    StorageService? storageService,
  })  : _client = client ?? Supabase.instance.client,
        _storageService = storageService ?? StorageService(),
        _dio = Dio();

  /// Export notes to PDF with embedded images
  Future<Uint8List> exportNotesToPDF({
    required List<String> noteIds,
    required bool isDarkMode,
    bool includeRoughWork = false,
  }) async {
    final pdf = pw.Document();
    
    for (final noteId in noteIds) {
      // Fetch note
      final noteResponse = await _client
          .from('notes')
          .select()
          .eq('id', noteId)
          .single();
      
      final note = Note.fromJson(noteResponse);
      
      // Fetch pages
      final pagesResponse = await _client
          .from('pages')
          .select()
          .eq('note_id', noteId)
          .order('page_number');
      
      final pages = (pagesResponse as List)
          .map((e) => Page.fromJson(e as Map<String, dynamic>))
          .where((p) => includeRoughWork || !p.isRoughWork)
          .toList();
      
      // Add note title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  note.title ?? 'Untitled Note',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: isDarkMode ? PdfColors.white : PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Date: ${_formatDate(note.date)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? PdfColors.grey300 : PdfColors.grey700,
                  ),
                ),
                if (note.metadata != null && note.metadata!.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Notes',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: isDarkMode ? PdfColors.white : PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    note.metadata!['content']?.toString() ?? '',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? PdfColors.grey300 : PdfColors.grey700,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
      
      // Add pages with embedded images
      for (final page in pages) {
        try {
          // Download image
          final imageBytes = await _storageService.downloadImageBytes(page.imageUrl);
          
          // Decode image to get dimensions
          final image = pw.MemoryImage(imageBytes);
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (page.isRoughWork)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.orange,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'Rough Work',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    if (page.isRoughWork) pw.SizedBox(height: 8),
                    pw.Text(
                      'Page ${page.pageNumber}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: isDarkMode ? PdfColors.grey300 : PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    // Embed image
                    pw.Center(
                      child: pw.Image(
                        image,
                        fit: pw.BoxFit.contain,
                        width: PdfPageFormat.a4.width - 40,
                      ),
                    ),
                    if (page.ocrText != null && page.ocrText!.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Divider(),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Extracted Text',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        page.ocrText!,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                      ),
                    ],
                    if (page.aiSummary != null && page.aiSummary!.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Divider(),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Summary',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        page.aiSummary!,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? PdfColors.grey300 : PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        } catch (e) {
          // If image download fails, create text-only page
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Page ${page.pageNumber}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? PdfColors.grey300 : PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Image: ${page.imageUrl}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? PdfColors.grey500 : PdfColors.grey600,
                      ),
                    ),
                    if (page.ocrText != null)
                      pw.Text(
                        page.ocrText!,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? PdfColors.white : PdfColors.black,
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        }
      }
    }
    
    return pdf.save();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Share/print PDF
  Future<void> sharePDF(Uint8List pdfBytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
}
