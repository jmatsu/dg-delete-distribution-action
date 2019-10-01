FROM buildpack-deps:stretch-curl

LABEL maintainer="jmatsu.drm@gmail.com"

LABEL "com.github.actions.name"="Delete a distribution from DeployGate"
LABEL "com.github.actions.description"="An action to delete a *distribution* from DeployGate on branch-delete"
LABEL "com.github.actions.icon"="trash"
LABEL "com.github.actions.color"="gray-dark"

RUN curl -sSL "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -o /jq
RUN chmod +x /jq
RUN ln -s /jq /usr/bin/jq

COPY VERSION /VERSION

COPY toolkit.sh /toolkit.sh

COPY entry-point.sh /entry-point.sh
RUN chmod +x /entry-point.sh

ENTRYPOINT ["/entry-point.sh"]