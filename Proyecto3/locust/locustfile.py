import os
import random
from datetime import datetime, timezone
from locust import HttpUser, task, between

class MilitaryTrafficSimulator(HttpUser):
    host = os.getenv("LOCUST_HOST")

    # Tiempo de espera entre peticiones de cada usuario simulado (entre 1 y 3 segundos)
    wait_time = between(1, 3)

    # Ruta del Gateway API. Se puede sobreescribir con LOCUST_PATH si cambiaste el carnet o el entorno.
    gateway_path = os.getenv("LOCUST_PATH", "/grpc-202300625")

    # Países permitidos según el Enum de gRPC en el proyecto
    COUNTRIES = ["USA", "RUS", "CHN", "ESP", "GTM"]

    def on_start(self):
        # El Gateway del proyecto expone HTTP en el puerto 80, no HTTPS.
        if getattr(self.client, "base_url", "").startswith("https://"):
            self.client.base_url = self.client.base_url.replace("https://", "http://", 1)
            self.host = self.client.base_url

    @task
    def send_military_report(self):
        # 1. Generar datos aleatorios según las reglas del proyecto
        country = random.choice(self.COUNTRIES)
        warplanes = random.randint(0, 50)
        warships = random.randint(0, 30)
        
        # Generar timestamp en formato ISO 8601 (UTC)
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        # 2. Estructurar el JSON
        payload = {
            "country": country,
            "warplanes_in_air": warplanes,
            "warships_in_water": warships,
            "timestamp": timestamp
        }

        # 3. Enviar la petición POST al Gateway API
        with self.client.post(
            self.gateway_path,
            json=payload,
            headers={"Content-Type": "application/json"},
            name=self.gateway_path,
            catch_response=True,
        ) as response:
            if response.status_code == 201 or response.status_code == 200:
                response.success()
            else:
                response.failure(f"Fallo con código {response.status_code}: {response.text}")