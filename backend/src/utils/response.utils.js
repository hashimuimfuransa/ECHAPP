const sendSuccess = (res, data, message = 'Success', statusCode = 200) => {
  res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

const sendError = (res, message = 'Something went wrong', statusCode = 500, errors = null) => {
  const response = {
    success: false,
    message
  };
  
  if (errors) {
    response.errors = errors;
  }
  
  res.status(statusCode).json(response);
};

const sendUnauthorized = (res, message = 'Unauthorized access') => {
  sendError(res, message, 401);
};

const sendForbidden = (res, message = 'Forbidden access') => {
  sendError(res, message, 403);
};

const sendNotFound = (res, message = 'Resource not found') => {
  sendError(res, message, 404);
};

module.exports = {
  sendSuccess,
  sendError,
  sendUnauthorized,
  sendForbidden,
  sendNotFound
};