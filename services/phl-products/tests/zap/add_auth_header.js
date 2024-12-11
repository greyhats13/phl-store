// File: services/phl-products/tests/zap/add_auth_header.js

function sendingRequest(msg, initiator, helper) {
  // Inject the Authorization header with the Bearer Token into every outgoing request
  msg.getRequestHeader().setHeader("Authorization", "Bearer YOUR_BEARER_TOKEN_HERE");
  msg.setRequestHeader(msg.getRequestHeader().toString());
}

function responseReceived(msg, initiator, helper) {
  // No action needed on response
}
