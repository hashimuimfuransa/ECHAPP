const mongoose = require('mongoose');

const platformSettingsSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true,
    default: 'general'
  },
  paymentInfo: {
    mtn_momo: {
      accountName: { type: String, default: '' },
      accountNumber: { type: String, default: '' },
      merchantCode: { type: String, default: '' },
      enabled: { type: Boolean, default: true }
    },
    airtel_money: {
      accountName: { type: String, default: '' },
      accountNumber: { type: String, default: '' },
      merchantCode: { type: String, default: '' },
      enabled: { type: Boolean, default: true }
    },
    bank_transfer: {
      bankName: { type: String, default: '' },
      accountName: { type: String, default: '' },
      accountNumber: { type: String, default: '' },
      swiftCode: { type: String, default: '' },
      enabled: { type: Boolean, default: true }
    },
    contactSupport: {
      phone: { type: String, default: '' },
      email: { type: String, default: '' },
      whatsapp: { type: String, default: '' }
    }
  },
  platformInfo: {
    name: { type: String, default: 'Excellence Coaching Hub' },
    description: { type: String, default: '' },
    contactEmail: { type: String, default: '' },
    contactPhone: { type: String, default: '' }
  },
  userManagement: {
    allowRegistration: { type: Boolean, default: true },
    requireEmailVerification: { type: Boolean, default: true },
    defaultUserRole: { type: String, default: 'Student' }
  },
  contentModeration: {
    requireManualCourseApproval: { type: Boolean, default: true },
    autoFilterSpam: { type: Boolean, default: true },
    allowCommentsOnCourses: { type: Boolean, default: true }
  },
  notifications: {
    enabled: { type: Boolean, default: true },
    email: { type: Boolean, default: true },
    push: { type: Boolean, default: false }
  },
  appearance: {
    theme: { type: String, default: 'Light' }
  },
  dataManagement: {
    autoSync: { type: Boolean, default: true },
    syncInterval: { type: Number, default: 30 }
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('PlatformSettings', platformSettingsSchema);
