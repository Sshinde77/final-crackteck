436v  0';jkhbnvd # API image and media response guide

## Purpose

Every JSON response served from `/api/*` now exposes a client-ready absolute URL for every persisted image/media value. This applies recursively, so the same behaviour works for top-level form responses and nested service, AMC, product, order, diagnosis, profile, and document records.

The database continues to store its original path (for example, `uploads/crm/quick-service/products/device.jpg`). No data migration is required.

## Response contract

The stored field is retained and a companion field ending in `_url` is added.

| Stored response field | New response field | Value type |
| --- | --- | --- |
| `image` | `image_url` | string or `null` |
| `main_product_image` | `main_product_image_url` | string or `null` |
| `additional_product_images` | `additional_product_images_url` | array of strings |
| `images` | `images_url` | array of strings |
| `before_photos` | `before_photos_url` | array of strings |
| `after_photos` | `after_photos_url` | array of strings |
| `profile` | `profile_url` | string or `null` |
| `receipt` | `receipt_url` | string or `null` |
| `document_file` | `document_file_url` | string or `null` |
| any field ending `_path` | the same field plus `_url` | string or `null` |

This also covers document and identity-image fields such as `aadhar_front_path`, `aadhar_back_path`, `pan_card_front_path`, `pan_card_back_path`, `driving_license_front_path`, `driving_license_back_path`, `passbook_pic`, `police_certificate`, `qualification_certifications`, and `address_proof`.

Example:

```json
{
  "main_product_image": "uploads/products/router.jpg",
  "main_product_image_url": "https://example.com/uploads/products/router.jpg",
  "images": ["uploads/crm/quick-service/products/router-side.jpg"],
  "images_url": ["https://example.com/uploads/crm/quick-service/products/router-side.jpg"]
}
```

Clients should render the `*_url` value. The original field is intentionally retained for backward compatibility and for administrative/debugging uses.

## URL resolution

| Stored value/source | Returned URL |
| --- | --- |
| Existing `https://...` Firebase/external URL | Returned unchanged |
| `uploads/...`, `receipts/...`, and other files written below `public/` | `APP_URL` + `/<stored-path>` |
| `diagnosis_photos/...` and `kyc_documents/...` written on Laravel's `public` disk | `APP_URL` + `/storage/<stored-path>` |
| `storage/...` | `APP_URL` + `/<stored-path>` |
| Empty/null value | `null` |

Set `APP_URL` in `.env` to the public HTTPS domain before production deployment. The Laravel public storage link must exist for `diagnosis_photos` and `kyc_documents` (`php artisan storage:link`).

## Image/media API inventory

All authenticated routes below are prefixed with `/api/v1` and require the configured JWT middleware unless marked public.

### Services, AMC, and customer equipment

| Endpoint | Form image input/storage | Image fields returned |
| --- | --- | --- |
| `GET /quick-services` | Service catalogue records | `image_url` when the covered-item record has `image` |
| `GET /services-list` | Service catalogue records | `image_url` |
| `GET /service-details/{id}` | Service catalogue record | `image_url` |
| `POST /submit-quick-service-request` | `products[n][images][]`; stored under `public/uploads/crm/quick-service/products/` in `service_request_products.images` or `amc_products.images` | nested `products[n].images_url` in the creation response |
| `GET /service-request-details/{id}` | Existing service-request product images | `products[n].images_url` |
| `GET /all-service-requests` | Submitted service-request products | `products[n].images_url` |
| `GET /customer-amc/{id}` | AMC product images | `amc_products[n].images_url` |
| `GET /customer-amcs` | AMC product images | `amc_products[n].images_url` |
| `GET /amc-plans` and `GET /amc-plan-details/{id}` | Plan/covered-item catalogue | `image_url` when a plan or covered item has an `image` column |

Product images live on `amc_products.images`; both the AMC list and detail endpoints now load this relation.

### Product and order APIs

| Endpoint | Image source | Image fields returned |
| --- | --- | --- |
| `GET /products`, `GET /products/{product_id}` | Warehouse product | `main_product_image_url`, `additional_product_images_url` |
| `GET /product`, `GET /product/{id}` | E-commerce product's nested `warehouse_product` | `warehouse_product.main_product_image_url`, `warehouse_product.additional_product_images_url` |
| `GET /all-product`, `GET /all-product/{id}` | Engineer product selection | The current query selects no image column; no image is returned until that endpoint selects product image fields |
| `GET /order`, `GET /order/{id}`, delivery order/return-order detail routes | Nested purchased warehouse products when loaded by the route | Product media receives the same `*_url` fields automatically |
| `GET /product/categories` | Category records | `image_url`/`icon_image_url` if present in the serialized category |

### Diagnosis and engineer workflow

| Endpoint | Form image input/storage | Image fields returned |
| --- | --- | --- |
| `POST /service-request/{id}/{product_id}/submit-diagnosis` | `before_photos[]`, `after_photos[]`, `diagnosis_list[n][images][]`; stored on the Laravel `public` disk under `diagnosis_photos/before`, `diagnosis_photos/after`, and `diagnosis_photos/list` | The submission acknowledgement has no media payload; retrieve the diagnosis/detail route to render stored photos |
| `GET /service-request/{id}/{product_id}/diagnosis-list` | Diagnosis records | `before_photos_url`, `after_photos_url`; any serialized image field receives a companion URL |
| `GET /service-request-product-diagnostics/{id}/{product_id}` | Customer diagnosis view | Product-part `main_product_image_url`; product media present in serialized product relations also receives URL fields |

### Image/document forms

| Endpoint | Uploaded field(s) | Stored location | Returned link |
| --- | --- | --- | --- |
| `POST /quick-service/{id}` | `image` | `public/uploads/crm/quick-services/` | `image_url` in the returned quick-service request |
| `POST /kyc/submit` | `document_file` (JPG, PNG, or PDF) | public disk `kyc_documents/` | existing `document_file_url` |
| `POST/PUT /aadhar-card...`, `POST/PUT /customer-pan-card...` | Aadhar/PAN front and back fields | `public/uploads/crm/customer/...` | `<field>_url` |
| Delivery vehicle/Aadhar/PAN endpoints | Driving licence, Aadhar, and PAN front/back fields | `public/uploads/e-commerce/delivery/...` | `<field>_url` |
| `POST /order/profile/{order_id}` | `profile` | `public/uploads/e-commerce/orders/profile/` | `profile_url` |
| `POST /staff-reimbursements` | `receipt` (image or PDF) | `public/receipts/` or Firebase | `receipt_url` |
| Staff/customer signup verification | PAN, Aadhar, licence, passbook, certificate, and address-proof fields | `public/uploads/...` or Firebase through `FileUpload` | matching `*_url` whenever that saved model is serialized |

## Implementation notes

`app/Http/Middleware/ExposeApiMediaUrls.php` is registered on Laravel's `api` middleware group in `bootstrap/app.php`. It transforms only JSON API responses, including errors/successes with nested arrays, and never mutates database paths.

`app/Support/ApiMediaUrl.php` performs the storage-aware conversion and leaves already absolute Firebase/external URLs untouched. Add a new upload field to the response simply by giving it a media-like name (`image`, `photo`, `profile`, `receipt`, `document_file`, `certificate`, `passbook`, `address_proof`, or a name ending in `_path`); the middleware will expose its companion URL automatically.
