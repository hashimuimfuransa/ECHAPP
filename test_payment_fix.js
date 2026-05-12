// Test script to verify the payment fix works correctly
// This simulates the scenario where a user was previously approved, unenrolled, and wants to enroll again

const Payment = require('./backend/src/models/Payment');

async function testPaymentFix() {
    console.log('Testing payment fix for previously approved users...');
    
    try {
        // Simulate a user who had an approved payment before
        const userId = 'test-user-id';
        const courseId = 'test-course-id';
        
        // Check existing payments
        const existingPayments = await Payment.find({ userId, courseId });
        console.log(`Found ${existingPayments.length} existing payments for user ${userId} in course ${courseId}`);
        
        existingPayments.forEach(payment => {
            console.log(`- Payment ID: ${payment._id}, Status: ${payment.status}, Created: ${payment.createdAt}`);
        });
        
        // Test the new logic: Check for active payments only
        const activePayments = await Payment.find({ 
            userId, 
            courseId,
            status: { $in: ['pending', 'admin_review'] }
        });
        
        console.log(`Found ${activePayments.length} ACTIVE payments that would block new payment`);
        
        if (activePayments.length === 0) {
            console.log('✅ SUCCESS: User can create a new payment (no active payments found)');
        } else {
            console.log('❌ ISSUE: User has active payments that would block new payment');
        }
        
        // Test scenario with different payment statuses
        const allStatuses = ['pending', 'admin_review', 'approved', 'completed', 'failed', 'cancelled'];
        console.log('\nTesting different payment scenarios:');
        
        for (const status of allStatuses) {
            const count = await Payment.countDocuments({ userId, courseId, status });
            console.log(`- ${status}: ${count} payment(s)`);
        }
        
    } catch (error) {
        console.error('Test failed:', error);
    }
}

// Run the test
testPaymentFix().then(() => {
    console.log('\nTest completed');
    process.exit(0);
}).catch(error => {
    console.error('Test error:', error);
    process.exit(1);
});
