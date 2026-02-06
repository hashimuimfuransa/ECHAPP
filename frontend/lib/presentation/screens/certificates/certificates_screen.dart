import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/repositories/certificate_repository.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';

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
      ),
      body: _buildCertificateContent(context),
    );
  }

  Widget _buildCertificateContent(BuildContext context) {
    // For now, we'll simulate fetching certificates from enrollment records
    // where certificateEligible is true
    return FutureBuilder<List<Course>>(
      future: _fetchCertificates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
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
              Icons.verified_outlined,
              size: 80,
              color: AppTheme.greyColor.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Certificates Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete courses to earn certificates',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Browse Courses',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateGrid(BuildContext context, List<Course> certificates) {
    return Padding(
      padding: ResponsiveBreakpoints.isDesktop(context)
          ? const EdgeInsets.all(32)
          : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'My Certificates (${certificates.length})',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveBreakpoints.isDesktop(context) ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: ResponsiveBreakpoints.isDesktop(context) ? 0.8 : 1.2,
              ),
              itemCount: certificates.length,
              itemBuilder: (context, index) {
                return _buildCertificateCard(context, certificates[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(BuildContext context, Course course) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewCertificate(context, course),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified,
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                course.title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.blackColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Certificate of Completion',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Course>> _fetchCertificates() async {
    // Fetch actual certificates from the API
    try {
      final certRepo = CertificateRepository();
      return await certRepo.getCertificates();
    } catch (e) {
      print('Error fetching certificates: $e');
      return [];
    }
  }

  void _viewCertificate(BuildContext context, Course course) {
    // Navigate to certificate details view
    // In a real implementation, this would show the actual certificate
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate'),
        content: Text('Congratulations on completing ${course.title}!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}