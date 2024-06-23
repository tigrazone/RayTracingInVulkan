
struct UniformBufferObject
{
	mat4 ModelView;
	mat4 Projection;
	mat4 ModelViewInverse;
	mat4 ProjectionInverse;
	float Aperture;
	float FocusDistance;
	float HeatmapScale;
	uint TotalNumberOfSamples;
	uint frameNum;
	uint RR_MIN_DEPTHeye;
	uint NumberOfSamples;
	uint NumberOfBounces;
	uint RandomSeed;
	bool HasSky;
	bool ShowHeatmap;
};
