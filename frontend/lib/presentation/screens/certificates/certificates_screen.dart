import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:intl/intl.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push('/help'),
          ),
        ],
      ),
      body: _buildCertificateContent(context),
    );
  }

  Widget _buildCertificateContent(BuildContext context) {
    return FutureBuilder<List<Certificate>>(
      future: _fetchCertificates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                TextButton(
                  onPressed: () => (context as Element).markNeedsBuild(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final certificates = snapshot.data ?? [];

        if (certificates.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildCertificateGrid(context, certificates);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 100,
              color: AppTheme.greyColor.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Achievements Await!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.blackColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your courses and pass exams to earn official certificates of completion.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Start Learning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateGrid(BuildContext context, List<Certificate> certificates) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return SingleChildScrollView(
      padding: isDesktop ? const EdgeInsets.all(40) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.workspace_premium, color: AppTheme.primaryGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Achievements',
                    style: TextStyle(
                      fontSize: isDesktop ? 32 : 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.blackColor,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'You have earned ${certificates.length} certificates',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : (ResponsiveBreakpoints.isTablet(context) ? 2 : 1),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: isDesktop ? 0.85 : 1.1,
            ),
            itemCount: certificates.length,
            itemBuilder: (context, index) {
              return _buildCertificateCard(context, certificates[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(BuildContext context, Certificate certificate) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewCertificate(context, certificate),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: AppTheme.primaryGreen,
                          size: 28,
                        ),
                      ),
                      _buildScoreBadge(certificate.percentage),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'OFFICIAL CERTIFICATE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completion of Course',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.blackColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.greyColor),
                      const SizedBox(width: 6),
                      Text(
                        'Issued: ${DateFormat('MMM dd, yyyy').format(certificate.issuedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewCertificate(context, certificate),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('View'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadCertificate(context, certificate),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up_rounded, color: Color(0xFF16A34A), size: 14),
          const SizedBox(width: 4),
          Text(
            '${percentage.toInt()}%',
            style: const TextStyle(
              color: Color(0xFF16A34A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Certificate>> _fetchCertificates() async {
    try {
      final certRepo = CertificateRepository();
      return await certRepo.getCertificates();
    } catch (e) {
      print('Error fetching certificates: $e');
      rethrow;
    }
  }

  void _viewCertificate(BuildContext context, Certificate certificate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certificate Preview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Official Document',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Certificate "Visual" representation
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 80, color: AppTheme.primaryGreen),
                          const SizedBox(height: 24),
                          const Text(
                            'CERTIFICATE OF COMPLETION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text('This is to certify that the user has successfully completed'),
                          const SizedBox(height: 12),
                          const Text(
                            'THE PRESCRIBED COURSE',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDetailItem('Grade', '${certificate.percentage.toInt()}%'),
                              const SizedBox(width: 40),
                              _buildDetailItem('Date', DateFormat('MM/dd/yyyy').format(certificate.issuedDate)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Serial Number: ${certificate.serialNumber}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[400], letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoRow(Icons.verified_outlined, 'Status', 'Verified & Valid'),
                    _buildInfoRow(Icons.score_outlined, 'Final Score', '${certificate.score.toStringAsFixed(1)} Points'),
                    _buildInfoRow(Icons.numbers_outlined, 'Serial No.', certificate.serialNumber),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _downloadCertificate(context, certificate);
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openOnlineCertificate(certificate),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open Online'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _downloadCertificate(BuildContext context, Certificate certificate) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing certificate download...')),
      );
      
      final certRepo = CertificateRepository();
      final path = await certRepo.downloadAndSaveCertificate(
        certificate.id, 
        fileName: 'Certificate_${certificate.serialNumber}.pdf'
      );
      
      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate saved to: $path'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => launchUrl(Uri.file(path)),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openOnlineCertificate(Certificate certificate) async {
    if (certificate.certificatePdfPath.isNotEmpty) {
      final uri = Uri.parse(certificate.certificatePdfPath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}