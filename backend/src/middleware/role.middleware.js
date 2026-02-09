const { sendForbidden } = require('../utils/response.utils');

const authorize = (...roles) => {
  return (req, res, next) => {
    console.log('=== ROLE MIDDLEWARE CHECK ===');
    console.log('Requested roles:', roles);
    console.log('Request URL:', req.url);
    console.log('User in request:', !!req.user);
    console.log('User role:', req.user?.role);
    console.log('User email:', req.user?.email);
    console.log('User ID:', req.user?.id);
    console.log('User firebase UID:', req.user?.firebaseUid);
    
    if (!req.user) {
      console.log('Authorization failed: No user found');
      return sendForbidden(res, 'Access denied. No user found.');
    }

    if (!roles.includes(req.user.role)) {
      console.log('Authorization failed: Insufficient permissions. User role:', req.user.role, 'Required roles:', roles);
      return sendForbidden(res, 'Access denied. Insufficient permissions. Required: ' + roles.join(', '));
    }

    console.log('Role authorization successful');
    next();
  };
};

module.exports = { authorize };