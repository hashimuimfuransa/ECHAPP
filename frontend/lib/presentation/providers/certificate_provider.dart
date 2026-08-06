import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepository();
});

/// The signed-in user's certificates.
///
/// Cached at the provider level so rebuilding the certificates screen (theme
/// change, keyboard, returning from a detail sheet) reuses the loaded list
/// instead of re-issuing the request.
final userCertificatesProvider = FutureProvider<List<Certificate>>((ref) async {
  return ref.read(certificateRepositoryProvider).getCertificates();
});
