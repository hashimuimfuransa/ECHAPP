const sendSuccess = (res, data, message = 'Success', statusCode = 200) => {
  res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

const sendError = (res, message = 'Internal Server Error', statusCode = 500, error = null) => {
  res.status(statusCode).json({
    success: false,
    message,
    error
  });
};

const sendNotFound = (res, message = 'Resource not found') => {
  res.status(404).json({
    success: false,
    message
  });
};

const sendUnauthorized = (res, message = 'Unauthorized') => {
  res.status(401).json({
    success: false,
    message
  });
};

const sendForbidden = (res, message = 'Forbidden') => {
  res.status(403).json({
    success: false,
    message
  });
};

module.exports = {
  sendSuccess,
  sendError,
  sendNotFound,
  sendUnauthorized,
  sendForbidden
};