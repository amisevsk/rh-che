package com.redhat.che.keycloak.token.provider.util;

/**
 * Utility class for extracting name used for project on OpenShift.io
 * from a given OpenShift username.
 *
 * <p> The name used to define OpenShift projects must be converted before
 * being used as a project name due to different limitations on format between
 * the two.
 */
public class OpenShiftUserToProjectNameConverter {

    public static String getProjectName(String openShiftUsername) {
        String projectName = openShiftUsername;
        if (projectName.contains("@")) {
            // Username is an email address
            projectName = projectName.split("@")[0];
        }
        projectName = projectName.replaceAll("\\.", "-");

        return projectName;
    }
}
