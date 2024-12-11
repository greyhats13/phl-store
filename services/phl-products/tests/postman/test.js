// Generate a random integer to append to product name to ensure uniqueness.
let randomInt = Math.floor(Math.random() * 100000); 
let productName = "Product-" + randomInt; 
let productDescription = "This is a sample product description " + randomInt;
let productPrice = 99.99;

// Validate that product name is not empty
pm.test("Validate product name is not empty", function() {
    pm.expect(productName).to.not.be.empty;
});

// Construct request body for product creation
let requestBody = {
    name: productName,
    description: productDescription,
    price: productPrice
};
pm.variables.set("productBody", JSON.stringify(requestBody));

// // If token is not set in environment, request it once and set it.
// // This logic ensures that if token is missing, we try to fetch it.
// if(!pm.environment.get("token")) {
//     pm.sendRequest({
//         url: pm.environment.get("base_url_oauth") + "/oauth2/token",
//         method: 'POST',
//         header: {
//             'Content-Type': 'application/json'
//         },
//         body: {
//             mode: 'raw',
//             raw: JSON.stringify({
//                 "grant_type": "client_credentials",
//                 "client_id": pm.environment.get("client_id"),
//                 "client_secret": pm.environment.get("client_secret")
//             })
//         }
//     }, function (err, res) {
//         if (err) {
//             console.error("Error obtaining token:", err);
//         } else {
//             // Set the token if response is successful
//             pm.environment.set("token", res.json().access_token);
//         }
//     });
// }

// Set the request headers, including Authorization and Content-Type
pm.request.headers.upsert({key: 'Content-Type', value: 'application/json'});
pm.request.headers.upsert({key: 'Authorization', value: 'Bearer ' + pm.environment.get("token")});

// Attach the body to the request
pm.request.body.raw = pm.variables.get("productBody");

// Validate that token is available before sending the request
pm.test("Token is available", function() {
    pm.expect(pm.environment.get("token")).to.not.be.undefined;
});


// Set the request URL using base_url environment variable
pm.request.url = pm.environment.get("base_url") + "/products";

// Set required headers
pm.request.headers.upsert({key: 'Accept', value: 'application/json'});
pm.request.headers.upsert({key: 'Authorization', value: 'Bearer ' + pm.environment.get("token")});

// If query parameters needed (e.g., pagination), set them here
// pm.request.url.addQueryParams({limit: '10', offset: '0'});

// Validate that token is available
pm.test("Token is available for GET products", function() {
    pm.expect(pm.environment.get("token")).to.not.be.undefined;
});
