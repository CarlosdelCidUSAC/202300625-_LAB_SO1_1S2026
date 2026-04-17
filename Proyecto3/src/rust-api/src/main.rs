use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
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
}

// 2. Endpoint /health para sondas de K8s y métricas de HPA
async fn health_check() -> impl IntoResponse {
    (StatusCode::OK, "OK")
}

// Endpoint raíz para health checks de Google Cloud Load Balancer
async fn root_handler() -> impl IntoResponse {
    (StatusCode::OK, "Rust API está funcionando")
}

// 3. Endpoint POST /reports
async fn receive_report(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<MilitaryReport>,
) -> impl IntoResponse {
    
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

#[tokio::main]
async fn main() {
    // Definir la URL del servicio Go (usar variable de entorno en GKE)
    let go_service_url = env::var("GO_SERVICE_URL")
        .unwrap_or_else(|_| "http://localhost:8081/api/reports".to_string());

    let shared_state = Arc::new(AppState {
        http_client: Client::new(),
        go_service_url,
    });

    // 4. Configurar enrutamiento
    let app = Router::new()
        .route("/", get(root_handler))
        .route("/health", get(health_check))
        .route("/reports", post(receive_report))
        .with_state(shared_state);

    // 5. Escuchar en 0.0.0.0:8080 para compatibilidad con contenedores en K8s
    let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
    println!("API Rust escuchando en http://0.0.0.0:8080");
    
    axum::serve(listener, app).await.unwrap();
}