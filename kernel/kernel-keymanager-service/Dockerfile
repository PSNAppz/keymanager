FROM ubuntu:20.04

ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}

# Can be passed during Docker build as build-time environment for GitHub branch to pick up configuration from.
ARG spring_config_label

# Can be passed during Docker build as build-time environment for Spring profiles active.
ARG active_profile

# Can be passed during Docker build as build-time environment for Config server URL.
ARG spring_config_url

# Can be passed during Docker build as build-time environment for Glowroot.
ARG is_glowroot

# Can be passed during Docker build as build-time environment for Artifactory URL.
ARG artifactory_url

# Can be passed during Docker build as build-time environment for HSM client zip file path.
ARG hsm_client_zip_path

# Environment variable for the active profile.
ENV active_profile_env=${active_profile}

# Environment variable for the GitHub branch.
ENV spring_config_label_env=${spring_config_label}

# Environment variable for Spring configuration URL.
ENV spring_config_url_env=${spring_config_url}

# Environment variable for Glowroot.
ENV is_glowroot_env=${is_glowroot}

# Environment variable for Artifactory URL.
ENV artifactory_url_env=${artifactory_url}

# Environment variable for IAM Adapter URL.
ENV iam_adapter_url_env=${iam_adapter_url}

# Environment variable for HSM client zip file path.
ENV hsm_zip_file_path=${hsm_client_zip_path}

# User-related arguments.
ARG container_user=mosip
ARG container_user_group=mosip
ARG container_user_uid=1001
ARG container_user_gid=1001

# Local directory for HSM client.
ARG hsm_local_dir=hsm-client
ENV hsm_local_dir_name=${hsm_local_dir}

# Install packages, create user, and install OpenJDK 11 and curl
RUN apt-get update \
    && apt-get install -y \
    unzip \
    sudo \
    wget \
    curl \
    software-properties-common \
    openjdk-11-jdk \
    && groupadd -g ${container_user_gid} ${container_user_group} \
    && useradd -u ${container_user_uid} -g ${container_user_group} -s /bin/sh -m ${container_user} \
    && adduser ${container_user} sudo \
    && echo "%sudo ALL=(ALL) NOPASSWD:/home/${container_user}/${hsm_local_dir}/install.sh" >> /etc/sudoers \
    && sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update \
    && apt-get install -y libc6-dev \
    && apt-get clean

# Set the working directory for the user
WORKDIR /home/${container_user}

ENV work_dir=/home/${container_user}

ARG loader_path=${work_dir}/additional_jars/
RUN mkdir -p ${loader_path}

ENV loader_path_env=${loader_path}

# Add necessary configuration and libraries
ADD configure_start.sh configure_start.sh
ADD ./lib/* "${loader_path_env}/"

RUN chmod +x configure_start.sh

# Copy the JAR files into the container
ADD ./target/*.jar /target/
RUN find /target -name '*.jar' -executable -type f -print0 | xargs -0 cp -t / \
    && rm -rf /target \
    && mv /*.jar ${work_dir}/kernel-keymanager-service.jar

# Change permissions of files inside the working directory
RUN chown -R ${container_user}:${container_user} /home/${container_user}

# Select container user for all tasks
USER ${container_user_uid}:${container_user_gid}

# Expose ports for the application
EXPOSE 8088
EXPOSE 9010

# Set the entrypoint and command to run the application
ENTRYPOINT [ "./configure_start.sh" ]
CMD if [ "$is_glowroot_env" = "present" ]; then \
    wget -q "${artifactory_url_env}"/artifactory/libs-release-local/io/mosip/testing/glowroot.zip ; \
    unzip glowroot.zip ; \
    rm -rf glowroot.zip ; \
    sed -i 's/<service_name>/kernel-keymanager-service/g' glowroot/glowroot.properties ; \
    wget -q "${iam_adapter_url_env}" -O "${loader_path_env}"/kernel-auth-adapter.jar; \
    java -jar -javaagent:glowroot/glowroot.jar -Dloader.path="${loader_path_env}" -Dspring.cloud.config.label="${spring_config_label_env}" -Dspring.profiles.active="${active_profile_env}" -Dspring.cloud.config.uri="${spring_config_url_env}" -XX:HeapDumpPath=/home/  ./kernel-keymanager-service.jar ; \
    else \
    wget -q "${iam_adapter_url_env}" -O "${loader_path_env}"/kernel-auth-adapter.jar; \
    java -jar -Dloader.path="${loader_path_env}" -Dspring.cloud.config.label="${spring_config_label_env}" -Dspring.profiles.active="${active_profile_env}" -Dspring.cloud.config.uri="${spring_config_url_env}" ./kernel-keymanager-service.jar ; \
    fi
