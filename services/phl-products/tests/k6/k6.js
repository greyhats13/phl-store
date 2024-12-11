// File: services/phl-products/tests/k6/k6.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom Metrics
export let errorRate = new Rate('errors');
export let responseTime = new Trend('response_time');

// Base URL and Bearer Token from environment variables
const BASE_URL = __ENV.BASE_URL || 'https://api.phl.blast.co.id';
const BEARER_TOKEN = __ENV.BEARER_TOKEN || '';

export let options = {
    scenarios: {
        get_products_by_id: {
            executor: 'constant-arrival-rate',
            rate: 100, // Requests per second matching the rate limit (80 RPS)
            timeUnit: '1s',
            duration: '2m', // Total test duration of 2 minutes
            preAllocatedVUs: 100, // Initial number of VUs
            maxVUs: 200, // Maximum number of VUs
        },
    },
    thresholds: {
        'http_reqs': ['count>9600'], // 80 RPS * 120 seconds = 9600 requests
        'errors': ['rate<0.01'], // Error rate below 1%
        'http_req_duration': ['p(95)<500'], // 95% of requests should be below 500ms
    },
};

let productIds = [];

export function setup() {
    const headers = {
        'Authorization': `Bearer ${BEARER_TOKEN}`,
        'Accept': 'application/json',
    };

    // Fetch the list of products to obtain valid IDs
    let res = http.get(`${BASE_URL}/products`, { headers });

    // Validate the response
    check(res, {
        'Setup - Status 200': (r) => r.status === 200,
        'Setup - Products Available': (r) => r.json().length > 0,
    });

    if (res.status !== 200 || res.json().length === 0) {
        console.error('No products available for testing.');
        return { productIds: [] };
    }

    // Extract product IDs for testing
    productIds = res.json().map(product => product.id);

    return { productIds };
}

export default function (data) {
    if (data.productIds.length === 0) {
        // No products to test against
        errorRate.add(1);
        return;
    }

    const headers = {
        'Authorization': `Bearer ${BEARER_TOKEN}`,
        'Accept': 'application/json',
    };

    // Select a random product ID from the list
    const randomIndex = Math.floor(Math.random() * data.productIds.length);
    const productId = data.productIds[randomIndex];

    // Perform the GET request to fetch the product by ID
    let res = http.get(`${BASE_URL}/products/${productId}`, { headers });

    // Validate the response
    let success = check(res, {
        'GET /products/{id} Status 200': (r) => r.status === 200,
        'GET /products/{id} Valid ID': (r) => r.json('id') === productId,
    });

    if (!success) {
        // Handle rate limiting (429 Too Many Requests) responses from AWS API Gateway
        if (res.status === 429) {
            console.warn(`Received 429 Too Many Requests for product ID: ${productId}`);
            // Implement a backoff strategy if necessary
            sleep(1); // Pause for 1 second before continuing
        }
        errorRate.add(1);
    }

    // Simulate user think time
    sleep(0.1);
}