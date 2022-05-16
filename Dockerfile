FROM python:3.9-slim-buster
WORKDIR /opt
RUN apt-get update && apt-get -y install gcc g++
RUN pip3 install --upgrade pip
COPY requirements.txt /opt
RUN pip3 install -r /opt/requirements.txt
COPY . /opt
# ENTRYPOINT ["/opt/startup.sh"]
# CMD ["sh","/opt/startup.sh"]
CMD ["python","-u","/opt/app.py"]