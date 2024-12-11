// File: services/phl-products/tests/k6/performance-test.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom Metrics
export let errorRate = new Rate('errors');
export let responseTime = new Trend('response_time');

const BASE_URL = __ENV.BASE_URL || 'https://api.phl.blast.co.id';
const BEARER_TOKEN = __ENV.BEARER_TOKEN || '';

export let options = {
    stages: [
        { duration: '2m', target: 100 }, // Ramp-up to 100 VUs
        { duration: '5m', target: 100 }, // Sustain 100 VUs
        { duration: '2m', target: 0 },   // Ramp-down to 0 VUs
    ],
    thresholds: {
        'http_reqs': ['count>1000'],               // Minimal request count
        'errors': ['rate<0.01'],                   // Error rate below 1%
        'response_time': ['p(95)<500'],            // 95% of responses below 500ms
    },
};

let productIds = [];

export function setup() {
    const headers = {
        'Authorization': `Bearer ${BEARER_TOKEN}`,
        'Accept': 'application/json',
    };

    // Get products data
    let res = http.get(`${BASE_URL}/products`, { headers });

    check(res, {
        'Setup - Status 200': (r) => r.status === 200,
        'Setup - Produk Tersedia': (r) => r.json().length > 0,
    });

    if (res.status !== 200 || res.json().length === 0) {
        console.error('Tidak ada produk yang tersedia untuk testing.');
        return { productIds: [] };
    }

    // Extract product IDs
    productIds = res.json().map(product => product.id);

    return { productIds };
}

export default function (data) {
    if (data.productIds.length === 0) {
        // No more pdoducts to test
        errorRate.add(1);
        return;
    }

    const headers = {
        'Authorization': `Bearer ${BEARER_TOKEN}`,
        'Accept': 'application/json',
    };

    // Choose product ID randomly
    const randomIndex = Math.floor(Math.random() * data.productIds.length);
    const productId = data.productIds[randomIndex];

    // Perform request to GET /products/{id}
    let res = http.get(`${BASE_URL}/products/${productId}`, { headers });

    let success = check(res, {
        'GET /products/{id} Status 200': (r) => r.status === 200,
        'GET /products/{id} Valid ID': (r) => r.json('id') === productId,
    });

    if (!success) {
        errorRate.add(1);
    }

    // Simulate user think-time
    sleep(0.1);
}