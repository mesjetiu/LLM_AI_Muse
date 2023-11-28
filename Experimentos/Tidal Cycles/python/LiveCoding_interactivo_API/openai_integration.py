import time
from openai import OpenAI
from threading import Thread

# Variables para controlar el estado de la API
api_call_in_progress = False
api_response_pending = None


def consult_openai_api(client, model, temperature, max_tokens, top_p, frequency_penalty, presence_penalty, wait_time_before_api, wait_time_after_api, messages, content, response_handler):
    """
    Consulta la API de OpenAI y maneja la respuesta.
    :param client: Cliente de OpenAI.
    :param model: Modelo de OpenAI a utilizar.
    :param temperature: Temperatura para las respuestas de la API.
    :param max_tokens: Máximo número de tokens en la respuesta.
    :param top_p: Parámetro top_p para la generación de texto.
    :param frequency_penalty: Penalización por frecuencia de uso de palabras.
    :param presence_penalty: Penalización por presencia de palabras.
    :param wait_time_before_api: Tiempo de espera antes de la consulta a la API.
    :param wait_time_after_api: Tiempo de espera después de la consulta a la API.
    :param messages: Mensajes para la conversación con la API.
    :param content: Contenido a enviar a la API.
    :param response_handler: Función para manejar la respuesta de la API.
    """
    global api_call_in_progress, api_response_pending
    api_call_in_progress = True
    time.sleep(wait_time_before_api)
    try:
        print("Consultando API de OpenAI...")
        messages[1]["content"] = content
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            top_p=top_p,
            frequency_penalty=frequency_penalty,
            presence_penalty=presence_penalty
        )
        api_response_pending = response.choices[0].message.content
        response_handler(api_response_pending)
    except Exception as e:
        print(f"Error en la llamada a la API de OpenAI: {e}")
    finally:
        api_call_in_progress = False
    time.sleep(wait_time_after_api)


def start_api_thread(client, model, temperature, max_tokens, top_p, frequency_penalty, presence_penalty, wait_time_before_api, wait_time_after_api, messages, content, response_handler):
    """
    Inicia un hilo para consultar la API de OpenAI.
    :param client: Cliente de OpenAI.
    :param model: Modelo de OpenAI a utilizar.
    :param temperature: Temperatura para las respuestas de la API.
    :param max_tokens: Máximo número de tokens en la respuesta.
    :param top_p: Parámetro top_p para la generación de texto.
    :param frequency_penalty: Penalización por frecuencia de uso de palabras.
    :param presence_penalty: Penalización por presencia de palabras.
    :param wait_time_before_api: Tiempo de espera antes de la consulta a la API.
    :param wait_time_after_api: Tiempo de espera después de la consulta a la API.
    :param messages: Mensajes para la conversación con la API.
    :param content: Contenido a enviar a la API.
    :param response_handler: Función para manejar la respuesta de la API.
    """
    if not api_call_in_progress:
        api_thread = Thread(
            target=consult_openai_api,
            args=(client, model, temperature, max_tokens, top_p, frequency_penalty, presence_penalty,
                  wait_time_before_api, wait_time_after_api, messages, content, response_handler)
        )
        api_thread.start()
