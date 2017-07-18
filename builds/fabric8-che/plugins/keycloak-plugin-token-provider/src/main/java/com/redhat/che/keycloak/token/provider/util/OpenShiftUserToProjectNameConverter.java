package com.redhat.che.keycloak.token.provider.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility class for extracting name used for project on OpenShift.io
 * from a given OpenShift username.
 *
 * <p> The name used to define OpenShift projects must be converted before
 * being used as a project name due to different limitations on format between
 * the two.
 */
public class OpenShiftUserToProjectNameConverter {

    private static final Logger LOG = LoggerFactory.getLogger(OpenShiftUserToProjectNameConverter.class);

    public static String getProjectName(String openShiftUsername) {
        String projectName = openShiftUsername;
        LOG.info("CONVERTER RAW: {}", projectName);
        if (projectName.contains("@")) {
            // Username is an email address
            projectName = projectName.split("@")[0];
        }
        projectName = projectName.replaceAll("\\.", "-");

        LOG.info("CONVERTER CONVERTED: {}", projectName);
        return projectName;
    }
}
