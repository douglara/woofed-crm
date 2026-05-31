# from agno.models.groq import Groq
from agno.models.openai import OpenAIChat
from agno.models.message import Message

from dotenv import load_dotenv
load_dotenv()

model = OpenAIChat(id="gpt-4.1-mini")

user_message = Message(role="user", content="Qual é a capital da França?")

assistant_message = Message(role="assistant", content="")

response = model.invoke(
	messages=[user_message],
	assistant_message=assistant_message
)

print(response)
