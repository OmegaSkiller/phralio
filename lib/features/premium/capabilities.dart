import '../../core/document.dart';

enum PremiumFeature { pdfReflow, imageReader }

abstract interface class EntitlementService {
  bool allows(PremiumFeature feature);
}

class FreeEntitlementService implements EntitlementService {
  const FreeEntitlementService();
  @override
  bool allows(PremiumFeature feature) => false;
}

abstract interface class PdfReflowService {
  Future<ReaderDocument> import(List<int> bytes);
}

class UnsupportedPdfReflowService implements PdfReflowService {
  const UnsupportedPdfReflowService();
  @override
  Future<ReaderDocument> import(List<int> bytes) => Future.error(
    UnsupportedError('PDF reflow is not available in this edition.'),
  );
}

abstract interface class OcrImportService {
  Future<ReaderDocument> import(List<int> bytes);
}

/// Composition boundary. It never treats an entitlement as an implementation.
class ReaderCapabilities {
  const ReaderCapabilities({
    this.entitlements = const FreeEntitlementService(),
    this.pdf,
  });
  final EntitlementService entitlements;
  final PdfReflowService? pdf;
  bool get canImportPdf =>
      pdf != null && entitlements.allows(PremiumFeature.pdfReflow);
}
