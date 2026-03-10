# Use the official Gradle image as a base for building
FROM gradle:8.12.0-jdk21 AS build

# Allow access to required ports
EXPOSE 7474
EXPOSE 7687

# Install Java 17
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk && \
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 2 && \
    update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac 2

# Set environment variable so Gradle sees both JDKs
ENV JAVA_HOME_17=/usr/lib/jvm/java-17-openjdk-amd64

# Install Neo4j and dependencies
RUN wget -O - https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /etc/apt/keyrings/neotechnology.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/neotechnology.gpg] https://debian.neo4j.com stable latest' > /etc/apt/sources.list.d/neo4j.list && \
    apt-get update && \
    apt-get install -y neo4j=1:2025.05.0

# Set the working directory
WORKDIR /home/gradle/src

# Clone the repository
RUN git clone https://github.com/JOyagdol/3dcitykg

COPY . /home/gradle/src/3dcitykg
# Change to project directory
WORKDIR /home/gradle/src/3dcitykg

# Cache Gradle dependencies
RUN gradle dependencies --no-daemon || true

# Build the application
RUN gradle build --no-daemon

# Replace the default Neo4j configuration
COPY config/neo4j.conf /etc/neo4j/neo4j.conf

# Run the application and start Neo4j
# CMD gradle run && neo4j consoles
CMD gradle run --no-daemon -Dorg.gradle.jvmargs="-Xmx2g" && neo4j console