Gue ingin melakukan API testing menggunakan Postman Collection
Gue memiliki product service yang memiliki 4 attributes yakni:
id: integer -> auto increment
name: string -> nama product (required)
description: string -> deskripsi product (optional)
price: float -> harga product (optional)

Dan gue memiliki 5 endpoint untuk product service tersebut:
Base Url Products: https://api.phl.blast.co.id
1. POST /products -> untuk create product. Response yang diharapkan adalah 201 Created
2. GET /products -> untuk list product. Response yang diharapkan adalah 200 OK
3. GET /products/{id} -> untuk get product by id. Response yang diharapkan adalah 200 OK
4. PUT /products/{id} -> untuk update product by id. Response yang diharapkan adalah 200 OK
5. DELETE /products/{id} -> untuk delete product by id. Response yang diharapkan adalah 204 No Content
Semua endpoint tersebut membutuhkan authorization bearer token.
POST https://oauth.phl.blast.co.id/oauth2/token
```json
{
  "grant_type": "client_credentials",
  "client_id": "3tkr18mpnmi6iucbpevcuvo59q",
  "client_secret": "2gc7ehpn15kt1ku8msrbtlvjas9nm9hgri0d346aa9ckefk48ni"
}
```

Skenario Testing. 
Tolong develop pre-request script dan post-response script untuk postman collection berikut:
1. POST /products (Membuat Produk)
Pre-request Script:
	1.	Generate Data Produk:
	•	Buat data produk yang akan dikirim, misalnya nama produk yang unik menggunakan fungsi seperti pm.variables.replaceIn('Product-{{randomString}}').
	•	Isi atribut opsional seperti deskripsi dan harga jika diperlukan.
  2. Generate JWT Token:
  •	Generate JWT token untuk autentikasi bearer token dan simpan dalam variabel lingkungan karena ini hanya dilakukan sekali hingga testing berakhir.
	3.	Set Headers:
	•	Set JWT Token authorization bearer.  Pastikan header Content-Type diset ke application/json
	4.	Validasi Data Input:
	•	Pastikan data yang akan dikirim memenuhi skema yang ditentukan (misalnya, nama tidak kosong).

Post-response Script:
	1.	Verifikasi Status Code:
	•	Pastikan status code adalah 201 Created.
	2.	Validasi Response Body:
	•	Periksa bahwa response body mengandung semua atribut yang dikirim, termasuk id yang di-generate otomatis.
	•	Pastikan name sesuai dengan yang dikirimkan.
	3.	Simpan Data untuk Penggunaan Selanjutnya:
	•	Simpan id produk yang baru dibuat ke dalam variabel environment untuk digunakan di endpoint lain.
	4.	Schema Validation:
	•	Validasi bahwa response mengikuti skema JSON yang diharapkan memiliki attribute id, name, description, price.

2. GET /products (Daftar Produk)

Pre-request Script:
	1.	Set Headers:
	•	Ambil JWT token pada environment variable dan set ke authorization header. Pastikan header Accept diset ke application/json.
	2.	Set Query Parameters (Jika Ada):
	•	Jika endpoint mendukung pagination atau filtering, set parameter yang diperlukan.

Post-response Script:
	1.	Verifikasi Status Code:
	•	Pastikan status code adalah 200 OK.
	2.	Validasi Response Body:
	•	Pastikan response adalah array.
	•	Periksa bahwa setiap objek produk dalam array memiliki atribut yang diharapkan (id, name, dll.).
	3.	Pengecekan Konten:
	•	Jika sebelumnya telah dibuat produk, pastikan produk tersebut ada dalam daftar.
	4.	Schema Validation:
	•	Validasi bahwa setiap objek produk mengikuti skema JSON yang diharapkan.

3. GET /products/{id} (Get Produk Berdasarkan ID)

Pre-request Script:
	1.	Set Path Variable:
	•	Pastikan variabel id sudah diatur, biasanya dari response POST sebelumnya.
	2.	Set Headers:
	•	Ambil JWT token pada environment variable dan set ke authorization header. Pastikan header Accept diset ke application/json.
  3. Pastikan id diambil dari environment variable yang di set pada post request sebelumnya

Post-response Script:
	1.	Verifikasi Status Code:
	•	Pastikan status code adalah 200 OK.
	2.	Validasi Response Body:
	•	Pastikan objek produk yang dikembalikan memiliki id yang sesuai.
	•	Periksa bahwa atribut lainnya (name, description, price) sesuai dengan data yang diharapkan.
	3.	Schema Validation:
	•	Validasi bahwa response mengikuti skema JSON yang diharapkan.

4. PUT /products/{id} (Update Produk Berdasarkan ID)

Pre-request Script:
	1.	Set Path Variable:
	•	Pastikan variabel id sudah diatur.
	2.	Generate Data Update:
	•	Buat data yang akan di-update, misalnya mengubah name atau price.
	3.	Set Headers:
	•	Ambil JWT token pada environment variable dan set ke authorization header./ Pastikan header Content-Type diset ke application/json.
	4.	Validasi Data Input:
	•	Pastikan data yang akan dikirim memenuhi skema yang ditentukan.
  5. Pastikan id diambil dari environment variable yang di set pada post request sebelumnya

Post-response Script:
	1.	Verifikasi Status Code:
	•	Pastikan status code adalah 200 OK.
	2.	Validasi Response Body:
	•	Pastikan atribut yang di-update sesuai dengan data yang dikirim.
	•	Periksa bahwa id tetap sama.
	3.	Schema Validation:
	•	Validasi bahwa response mengikuti skema JSON yang diharapkan.
	4.	Cek Konsistensi Data:
	•	Optional: Lakukan GET pada produk yang di-update untuk memastikan perubahan tersimpan.

5. DELETE /products/{id} (Hapus Produk Berdasarkan ID)

Pre-request Script:
	1.	Set Path Variable:
	•	Pastikan variabel id sudah diatur.
	2.	Set Headers:
	•	PAmbil JWT token pada environment variable dan set ke authorization header./ astikan header Accept diset ke application/json atau sesuai kebutuhan.
  3. Pastikan id diambil dari environment variable yang di set pada post request sebelumnya

Post-response Script:
	1.	Verifikasi Status Code:
	•	Pastikan status code adalah 204 No Content.
	2.	Cek Penghapusan:
	•	Optional: Lakukan GET pada produk yang dihapus untuk memastikan produk tersebut tidak ada (seharusnya mendapatkan 404 Not Found).
	3.	Pembersihan Variabel:
	•	Hapus atau reset variabel id jika diperlukan.

Catatan Umum Best Practices:
	•	Penggunaan Variabel:
	•	Manfaatkan variabel lingkungan atau koleksi untuk menyimpan data seperti id produk yang dapat digunakan di berbagai request.
	•	Error Handling:
	•	Tangani kemungkinan error atau status code yang tidak diharapkan dengan memberikan pesan yang jelas.
	•	Reusability:
	•	Buat skrip yang dapat digunakan kembali untuk berbagai request jika memungkinkan, misalnya autentikasi.
	•	Keamanan:
	•	Jaga kerahasiaan data sensitif seperti token autentikasi dengan tidak memasukkannya langsung dalam skrip.
	•	Documentation:
	•	Dokumentasikan skrip dan variabel yang digunakan agar mudah dipahami dan dikelola oleh tim.

Dengan mengikuti daftar tugas di atas, Anda dapat memastikan bahwa setiap endpoint diuji secara menyeluruh dan konsisten, serta memudahkan integrasi dengan GitHub Actions untuk otomatisasi pengujian.

Buatkan 

Skenario testing:
Untuk mendapatkan JWT token untuk authorization bearer, api testing lo harus melakukan hit ke.
Nanti value dari grant_type, client_id, dan client_secret akan lo ambil dari github action secrets.
Proses generate token hanya lo lakukan sekali sampe CI/CD berakhir
```curl
curl --location 'https://oauth.phl.blast.co.id/oauth2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Cookie: XSRF-TOKEN=52a7aa51-b736-45df-8fe9-b18b320444bf' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'client_id=3tkr18mpnmi6iucbpevcuvo59q' \
--data-urlencode 'client_secret=2gc7ehpn15kt1ku8msrbtlvjas9nm9hgri0d346aa9ckefk48ni'
```
Lalu gunakan jwt token tersebut untuk melakukan API testing dari Post collection dibawah.
Gue telah menyediakan postman collection buat lo tapi id nya masih di hardcode.
Lo ga boleh menggunakan id tersebut untuk request selanjutnya karena bisa saja datanya udah dihapus.
Test pertama lo harus melakukan create product terlebih dahulu 'POST products' terlebih da, lalu ambil id dari create product tersebut.
Lalu id tersebut lo gunakan untuk  ambil data product 'GET /products/{id}'. Lalu setelah itu lo update data product tersebut 'PUT /products/{id}'yaitu name dan pricenya, lo bisa random untuk nama, dan price product. Lalu setelah itu lo hit list. product tersebut GET /products'. Setelah itu baru lo delete product yang lo buat tadi 'DELETE /products/{id}. Ulangi hal tersebut sebanyak 5 kali.

CI/CD:

Okay gue sekarang ingin mengintegrasikan testing gue ke CI/C Github Actions.
API testing ini akan masuk dalam stage "End to End testing" setelah stage deployment.
Lo bisa mengambil client_id dan client_secret dari github action secrets yang lo butuhkan untuk mengenerate token.
Token itu bisa lo simpan di environment.json untuk digunakan oleh newman.
Gue menginginkan test ini dijalankan dengan iterasi 5 kali dengan delay 200ms menit setiap iterasi.
Gunakan newman-reporter-htmlextra untuk menghasilkan report hasil testing dan di upload ke S3 dan autahentication ke AWS menggunakan github-oidc dengan assume role.

Berikut code github action gue saat ini:
github-ci.yml
```yml
name: CI/CD Pipeline for phl-products

on:
  push:
    branches:
      - main
      - dev
    paths:
      - "services/phl-products/**"
    tags:
      - "v*"

permissions:
  id-token: write # This is required for requesting the JWT
  contents: read # This is required for actions/checkout
jobs:
  build_push_tag:
    name: Build, Push, Tag
    runs-on: ubuntu-latest
    # needs: test_and_coverages
    # if: ${{ needs.test_and_coverages.outputs.quality_gate_status != 'FAILED' && (github.ref == 'refs/heads/dev' || github.ref == 'refs/heads/main') }}
    if: ${{ github.ref == 'refs/heads/dev' || github.ref == 'refs/heads/main' }}
    outputs:
      image_tag_sha: ${{ steps.set_image_tag.outputs.image_tag_sha }}
      chart_path: ${{ steps.set_image_tag.outputs.chart_path }}
      registry: ${{ steps.login-ecr.outputs.registry }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          # audience: sts.amazonaws.com
          aws-region: ${{ vars.AWS_REGION }}
          role-to-assume: ${{ vars.GH_OIDC_ROLE_ARN }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Retrieve ECR repo and Set Image Tag vased on environment
        id: set_image_tag
        run: |
          echo "GITHUB_REF: $GITHUB_REF"
          # if the branch is dev, tag the image as alpha
          if [[ $GITHUB_REF == refs/heads/dev ]]; then
            echo "image_tag_sha=alpha-${GITHUB_SHA:0:7}" >> $GITHUB_OUTPUT
            echo "chart_path=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_OUTPUT
            echo "IMAGE_TAG_SHA=alpha-${GITHUB_SHA:0:7}" >> $GITHUB_ENV
            echo "IMAGE_TAG_LATEST=alpha-latest" >> $GITHUB_ENV
            echo "CHART_PATH=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_ENV
          # if the branch is main, tag the image as beta
          elif [[ $GITHUB_REF == refs/heads/main ]]; then
            echo "image_tag_sha=beta-${GITHUB_SHA:0:7}" >> $GITHUB_OUTPUT
            echo "chart_path=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_OUTPUT
            echo "IMAGE_TAG_LATEST=beta-latest" >> $GITHUB_ENV
            echo "IMAGE_TAG_SHA=beta-${GITHUB_SHA:0:7}" >> $GITHUB_ENV
            echo "CHART_PATH=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_ENV
          fi

      - name: Build, Tag, and Push
        uses: docker/build-push-action@v6.9.0
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          context: ./services/phl-products/
          # Distroless
          # file: ./Dockerfile-distroless
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ vars.PRODUCTS_SVC_NAMING_STANDARD }}:${{ env.IMAGE_TAG_SHA }}
            ${{ env.REGISTRY }}/${{ vars.PRODUCTS_SVC_NAMING_STANDARD }}:${{ env.IMAGE_TAG_LATEST }}
          platforms: linux/amd64
          # # multi-platform
          # platforms: linux/amd64,linux/arm64

  deployment:
    environment: phl-products
    name: Deployment
    runs-on: ubuntu-latest
    needs: [build_push_tag]
    if: ${{ needs.build_push_tag.result == 'success'}}
    steps:
      - name: Trigger ArgoCD Sync by updating the helm chart
        run: |
          echo "IMAGE_TAG_SHA: ${{ needs.build_push_tag.outputs.image_tag_sha }}"
          echo "CHART_PATH: ${{ needs.build_push_tag.outputs.chart_path }}"
          eval "$(ssh-agent -s)"
          echo "${{ secrets.ARGOCD_SSH }}" > id_rsa
          chmod 400 id_rsa
          ssh-add id_rsa
          git clone git@github.com:${{ vars.GH_OWNER }}/${{ vars.GH_REPO_NAME }}.git
          echo ${{ vars.GH_REPO_NAME }}/${{ needs.build_push_tag.outputs.chart_path }}
          cd ${{ vars.GH_REPO_NAME }}/${{ needs.build_push_tag.outputs.chart_path }}
          sed -i "s|repository: .*|repository: ${{ needs.build_push_tag.outputs.registry }}/${{ vars.PRODUCTS_SVC_NAMING_STANDARD }}|" values.yaml
          sed -i "s/appVersion: \".*\"/appVersion: \"${{ needs.build_push_tag.outputs.image_tag_sha }}\"/" Chart.yaml
          git add values.yaml Chart.yaml
          git config --global user.email "imam.arief.rhmn@gmail.com"
          git config --global user.name "greyhats13"
          git commit -m "Update image tag to ${{ needs.build_push_tag.outputs.image_tag_sha }}"
          git push origin main
```

Berikut adalah postman collection v2.1 gue
phl-products.postman_collection.json
```json
{
	"info": {
		"_postman_id": "6f552e26-e166-428c-a220-1845071da8bf",
		"name": "phl-products",
		"description": "Pigeonhole sample Crud product services",
		"schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
		"_exporter_id": "17496406",
		"_collection_link": "https://cloudy-comet-657520.postman.co/workspace/80a25a47-86cf-491e-a426-a186d45351a6/collection/17496406-6f552e26-e166-428c-a220-1845071da8bf?action=share&source=collection_link&creator=17496406"
	},
	"item": [
		{
			"name": "Create Product",
			"request": {
				"auth": {
					"type": "bearer",
					"bearer": [
						{
							"key": "token",
							"value": "{{jwt_token}}",
							"type": "string"
						}
					]
				},
				"method": "POST",
				"header": [],
				"body": {
					"mode": "raw",
					"raw": "{\n    \"name\": \"Nasi\",\n    \"description\": \"Nasi kuning\",\n    \"price\": 35.00\n}",
					"options": {
						"raw": {
							"language": "json"
						}
					}
				},
				"url": {
					"raw": "{{base_url}}/products",
					"host": [
						"{{base_url}}"
					],
					"path": [
						"products"
					]
				}
			},
			"response": []
		},
		{
			"name": "List Product",
			"request": {
				"auth": {
					"type": "bearer",
					"bearer": [
						{
							"key": "token",
							"value": "{{jwt_token}}",
							"type": "string"
						}
					]
				},
				"method": "GET",
				"header": [],
				"url": {
					"raw": "{{base_url}}/products",
					"host": [
						"{{base_url}}"
					],
					"path": [
						"products"
					]
				}
			},
			"response": []
		},
		{
			"name": "Get Product",
			"request": {
				"auth": {
					"type": "bearer",
					"bearer": [
						{
							"key": "token",
							"value": "{{jwt_token}}",
							"type": "string"
						}
					]
				},
				"method": "GET",
				"header": [],
				"url": {
					"raw": "{{base_url}}/products/24",
					"host": [
						"{{base_url}}"
					],
					"path": [
						"products",
						"24"
					]
				}
			},
			"response": []
		},
		{
			"name": "Update Product",
			"request": {
				"auth": {
					"type": "bearer",
					"bearer": [
						{
							"key": "token",
							"value": "{{jwt_token}}",
							"type": "string"
						}
					]
				},
				"method": "PUT",
				"header": [],
				"body": {
					"mode": "raw",
					"raw": "{\n    \"price\": 25.00\n}",
					"options": {
						"raw": {
							"language": "json"
						}
					}
				},
				"url": {
					"raw": "{{base_url}}/products/24",
					"host": [
						"{{base_url}}"
					],
					"path": [
						"products",
						"24"
					]
				}
			},
			"response": []
		},
		{
			"name": "Delete Product",
			"request": {
				"auth": {
					"type": "bearer",
					"bearer": [
						{
							"key": "token",
							"value": "{{jwt_token}}",
							"type": "string"
						}
					]
				},
				"method": "DELETE",
				"header": [],
				"url": {
					"raw": "{{base_url}}/products/23",
					"host": [
						"{{base_url}}"
					],
					"path": [
						"products",
						"23"
					]
				}
			},
			"response": []
		}
	]
}
```

Berikut code github action gue saat ini:
github-ci.yml
```yml
name: CI/CD Pipeline for phl-products

on:
  push:
    branches:
      - main
      - dev
    paths:
      - "services/phl-products/**"
    tags:
      - "v*"

permissions:
  id-token: write # This is required for requesting the JWT
  contents: read # This is required for actions/checkout
jobs:
  build_push_tag:
    name: Build, Push, Tag
    runs-on: ubuntu-latest
    # needs: test_and_coverages
    # if: ${{ needs.test_and_coverages.outputs.quality_gate_status != 'FAILED' && (github.ref == 'refs/heads/dev' || github.ref == 'refs/heads/main') }}
    if: ${{ github.ref == 'refs/heads/dev' || github.ref == 'refs/heads/main' }}
    outputs:
      image_tag_sha: ${{ steps.set_image_tag.outputs.image_tag_sha }}
      chart_path: ${{ steps.set_image_tag.outputs.chart_path }}
      registry: ${{ steps.login-ecr.outputs.registry }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          # audience: sts.amazonaws.com
          aws-region: ${{ vars.AWS_REGION }}
          role-to-assume: ${{ vars.GH_OIDC_ROLE_ARN }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Retrieve ECR repo and Set Image Tag vased on environment
        id: set_image_tag
        run: |
          echo "GITHUB_REF: $GITHUB_REF"
          # if the branch is dev, tag the image as alpha
          if [[ $GITHUB_REF == refs/heads/dev ]]; then
            echo "image_tag_sha=alpha-${GITHUB_SHA:0:7}" >> $GITHUB_OUTPUT
            echo "chart_path=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_OUTPUT
            echo "IMAGE_TAG_SHA=alpha-${GITHUB_SHA:0:7}" >> $GITHUB_ENV
            echo "IMAGE_TAG_LATEST=alpha-latest" >> $GITHUB_ENV
            echo "CHART_PATH=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_ENV
          # if the branch is main, tag the image as beta
          elif [[ $GITHUB_REF == refs/heads/main ]]; then
            echo "image_tag_sha=beta-${GITHUB_SHA:0:7}" >> $GITHUB_OUTPUT
            echo "chart_path=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_OUTPUT
            echo "IMAGE_TAG_LATEST=beta-latest" >> $GITHUB_ENV
            echo "IMAGE_TAG_SHA=beta-${GITHUB_SHA:0:7}" >> $GITHUB_ENV
            echo "CHART_PATH=gitops/charts/app/${{ vars.PRODUCTS_SVC_NAME }}" >> $GITHUB_ENV
          fi

      - name: Build, Tag, and Push
        uses: docker/build-push-action@v6.9.0
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        with:
          context: ./services/phl-products/
          # Distroless
          # file: ./Dockerfile-distroless
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ vars.PRODUCTS_SVC_NAMING_STANDARD }}:${{ env.IMAGE_TAG_SHA }}
            ${{ env.REGISTRY }}/${{ vars.PRODUCTS_SVC_NAMING_STANDARD }}:${{ env.IMAGE_TAG_LATEST }}
          platforms: linux/amd64
          # # multi-platform
          # platforms: linux/amd64,linux/arm64

  deployment:
    environment: phl-products
    name: Deployment
    runs-on: ubuntu-latest
    needs: [build_push_tag]
    if: ${{ needs.build_push_tag.result == 'success'}}
    steps:
      - name: Trigger ArgoCD Sync by updating the helm chart
        run: |
          echo "IMAGE_TAG_SHA: ${{ needs.build_push_tag.outputs.image_tag_sha }}"
          echo "CHART_PATH: ${{ needs.build_push_tag.outputs.chart_path }}"
          eval "$(ssh-agent -s)"
          echo "${{ secrets.ARGOCD_SSH }}" > id_rsa
          chmod 400 id_rsa
          ssh-add id_rsa
          git clone git@github.com:${{ vars.GH_OWNER }}/${{ vars.GH_REPO_NAME }}.git
          echo ${{ vars.GH_REPO_NAME }}/${{ needs.build_push_tag.outputs.chart_path }}
          cd ${{ vars.GH_REPO_NAME }}/${{ needs.build_push_tag.outputs.chart_path }}
          sed -i "s|repository: .*|repository: ${{ needs.build_push_tag.outputs.registry }}/${{ vars.PRODUCTS_SVC_NAMING_STANDARD }}|" values.yaml
          sed -i "s/appVersion: \".*\"/appVersion: \"${{ needs.build_push_tag.outputs.image_tag_sha }}\"/" Chart.yaml
          git add values.yaml Chart.yaml
          git config --global user.email "imam.arief.rhmn@gmail.com"
          git config --global user.name "greyhats13"
          git commit -m "Update image tag to ${{ needs.build_push_tag.outputs.image_tag_sha }}"
          git push origin main
```