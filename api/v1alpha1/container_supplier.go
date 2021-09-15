package v1alpha1

import corev1 "k8s.io/api/core/v1"

type getContainerReq struct {
	env             []corev1.EnvVar
	imageFormat     string
	imagePullPolicy corev1.PullPolicy
	lifecycle       *corev1.Lifecycle
	runnerImage     string
	securityContext *corev1.SecurityContext
	volumeMounts    []corev1.VolumeMount
}

type containerSupplier interface {
	getContainer(req getContainerReq) corev1.Container
}

type volumeMountSupplier interface {
	getVolumeMount() corev1.VolumeMount
}
