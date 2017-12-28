FROM python:3.6.4-slim
LABEL mantainer="Angelo Carbone <angelo.carbone@gmail.com>"
WORKDIR /app
COPY . /app
RUN pip --no-cache-dir install requests tqdm jupyter
EXPOSE 8888

# Run app.py when the container launches
CMD ["jupyter", "notebook", "--ip='*'", "--port=8888", "--no-browser", "--allow-root"]
