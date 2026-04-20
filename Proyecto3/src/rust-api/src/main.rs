use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use chrono::{DateTime, Utc};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;
use std::sync::Arc;
use tokio::net::TcpListener;

// 1. Estructura exacta solicitada en el proyecto
#[derive(Deserialize, Serialize, Debug)]
struct MilitaryReport {
    country: String,
    warplanes_in_air: u32,
    warships_in_water: u32,
    timestamp: DateTime<Utc>,
}

// Estado compartido para inyectar el cliente HTTP y la URL del servicio Go
struct AppState {
    http_client: Client,
    go_service_url: String,
    go_dapr_service_url: String,
}

fn is_valid_country(country: &str) -> bool {
    matches!(country, "USA" | "RUS" | "CHN" | "ESP" | "GTM")
}

// 2. Endpoint /health para sondas de K8s y métricas de HPA
async fn health_check() -> impl IntoResponse {
    (StatusCode::OK, "OK")
}

// Endpoint raíz para health checks de Google Cloud Load Balancer
async fn root_handler() -> impl IntoResponse {
    (StatusCode::OK, "Rust API está funcionando")
}

// Health response for routed endpoints where Gateway may perform GET checks.
async fn reports_health() -> impl IntoResponse {
    (StatusCode::OK, "Reports endpoint ready")
}

// Health response for dapr forwarding endpoint.
async fn dapr_health() -> impl IntoResponse {
    (StatusCode::OK, "Dapr endpoint ready")
}

// 3. Endpoint POST /reports
async fn receive_report(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<MilitaryReport>,
) -> impl IntoResponse {
    if !is_valid_country(payload.country.as_str()) {
        let response_body = serde_json::json!({
            "status": "error",
            "message": "Invalid country. Allowed values: USA, RUS, CHN, ESP, GTM"
        });
        return (StatusCode::BAD_REQUEST, Json(response_body));
    }

    
    // El payload ya fue validado automáticamente por Serde.
    // Ahora enviamos el JSON al Deployment de Go según la arquitectura.
    let response = state
        .http_client
        .post(&state.go_service_url)
        .json(&payload)
        .send()
        .await;

    match response {
        Ok(res) if res.status().is_success() => {
            let response_body = serde_json::json!({
                "status": "success",
                "message": "Report forwarded to Go service successfully"
            });
            (StatusCode::CREATED, Json(response_body))
        }
        Ok(res) => {
            let error_msg = format!("Go service returned error: {}", res.status());
            let response_body = serde_json::json!({ "status": "error", "message": error_msg });
            (StatusCode::BAD_GATEWAY, Json(response_body))
        }
        Err(e) => {
            let error_msg = format!("Failed to connect to Go service: {}", e);
            let response_body = serde_json::json!({ "status": "error", "message": error_msg });
            (StatusCode::INTERNAL_SERVER_ERROR, Json(response_body))
        }
    }
}

// 4. Endpoint POST /dapr que reenvia al /dapr/reports del servicio Go
async fn receive_dapr_report(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<MilitaryReport>,
) -> impl IntoResponse {
    if !is_valid_country(payload.country.as_str()) {
        let response_body = serde_json::json!({
            "status": "error",
            "message": "Invalid country. Allowed values: USA, RUS, CHN, ESP, GTM"
        });
        return (StatusCode::BAD_REQUEST, Json(response_body));
    }

    let response = state
        .http_client
        .post(&state.go_dapr_service_url)
        .json(&payload)
        .send()
        .await;

    match response {
        Ok(res) if res.status().is_success() => {
            let response_body = serde_json::json!({
                "status": "success",
                "message": "Report forwarded to Go Dapr endpoint successfully"
            });
            (StatusCode::CREATED, Json(response_body))
        }
        Ok(res) => {
            let error_msg = format!("Go Dapr endpoint returned error: {}", res.status());
            let response_body = serde_json::json!({ "status": "error", "message": error_msg });
            (StatusCode::BAD_GATEWAY, Json(response_body))
        }
        Err(e) => {
            let error_msg = format!("Failed to connect to Go Dapr endpoint: {}", e);
            let response_body = serde_json::json!({ "status": "error", "message": error_msg });
            (StatusCode::INTERNAL_SERVER_ERROR, Json(response_body))
        }
    }
}

#[tokio::main]
async fn main() {
    // Definir la URL del servicio Go (usar variable de entorno en GKE)
    let go_service_url = env::var("GO_SERVICE_URL")
        .unwrap_or_else(|_| "http://localhost:8081/api/reports".to_string());
    let go_dapr_service_url = env::var("GO_DAPR_SERVICE_URL")
        .unwrap_or_else(|_| "http://localhost:8081/dapr/reports".to_string());

    let shared_state = Arc::new(AppState {
        http_client: Client::new(),
        go_service_url,
        go_dapr_service_url,
    });

    // 5. Configurar enrutamiento
    let app = Router::new()
        .route("/", get(root_handler))
        .route("/health", get(health_check))
        .route("/reports", get(reports_health).post(receive_report))
        // Compatibility route if Gateway rewrite is not active in some environments.
        .route("/grpc-202300625", get(reports_health).post(receive_report))
        .route("/dapr", get(dapr_health).post(receive_dapr_report))
        .route("/dapr-202300625", get(dapr_health).post(receive_dapr_report))
        .with_state(shared_state);

    // 6. Escuchar en 0.0.0.0:8080 para compatibilidad con contenedores en K8s
    let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
    println!("API Rust escuchando en http://0.0.0.0:8080");
    
    axum::serve(listener, app).await.unwrap();
}