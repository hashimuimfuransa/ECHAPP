const mongoose = require('mongoose');
require('./src/config/database');

const Payment = require('./src/models/Payment');

async function testSimpleQuery() {
  try {
    console.log('=== Testing Simple Query ===');
    
    // Simple count query
    const count = await Payment.countDocuments({});
    console.log('Payment count:', count);
    
    // Simple find without populate
    const payments = await Payment.find({}).limit(5);
    console.log('Simple find results:', payments.length);
    
    payments.forEach((p, i) => {
      console.log(`${i+1}. ID: ${p._id}, Status: ${p.status}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

testSimpleQuery();