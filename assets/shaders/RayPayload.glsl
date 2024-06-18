
struct RayPayload
{
	vec4 ColorAndDistance; // rgb + t
	vec4 ScatterDirection; // xyz + w (is scatter needed)
	uvec4 RandomSeed;
};
