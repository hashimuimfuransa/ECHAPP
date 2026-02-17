import '../../models/certificate.dart';
import '../../services/api/certificate_service.dart';

class CertificateRepository {
  final CertificateService _certificateService;

  CertificateRepository({CertificateService? certificateService})
      : _certificateService = certificateService ?? CertificateService();

  /// Get user's certificates
  Future<List<Certificate>> getCertificates() async {
    return await _certificateService.getCertificates();
  }

  /// Download a specific certificate
  Future<String> downloadCertificate(String certificateId) async {
    return await _certificateService.downloadCertificate(certificateId);
  }

  /// Get certificates by course ID
  Future<List<Certificate>> getCertificatesByCourse(String courseId) async {
    return await _certificateService.getCertificatesByCourse(courseId);
  }

  /// Check if user is eligible for a certificate for a specific course
  Future<bool> isCertificateEligible(String courseId) async {
    return await _certificateService.isCertificateEligible(courseId);
  }
}
