#extension GL_EXT_control_flow_attributes : require

#define pcg4d(v) \
	v = v * 1664525u + 1013904223u; \
	v.x += v.y * v.w;	\
	v.y += v.z * v.x;	\
	v.z += v.x * v.y;	\
	v.w += v.y * v.z;	\
	v = v ^ (v >> 16u);	\
	v.x += v.y * v.w;	\
	v.y += v.z * v.x;	\
	v.z += v.x * v.y;	\
	v.w += v.y * v.z


// Returns a float between 0 and 1
#define uint_to_float(x) ( uintBitsToFloat(0x3f800000 | ((x) >> 9)) - 1.0f )

#define InitRandomSeed(val0, val1, frame_num) ( uvec4(val0, val1, frame_num, 0) )

float RandomFloat(inout uvec4 v)
{
	pcg4d(v);
	return uint_to_float(v.x);
}

vec2 RandomFloat2(inout uvec4 v)
{
	pcg4d(v);
	return uint_to_float(v.xy);
}

#define e_5		0.00001f
#define PI_4	0.78539816339744830961566084581988f
#define TWO_PI	6.283185307179586476925286766559f

//#define NEARzero 1e-35f
#define NEARzero e_5
#define isZERO(x) ((x)>-NEARzero && (x)<NEARzero)

vec2 concentric_sample_disk(vec2 offset) {
    offset += offset - vec2(1);
    if (isZERO(offset.x) && isZERO(offset.y)) {
		return vec2(0);
	}

	float theta;

	if (abs(offset.x) > abs(offset.y)) {
        theta = PI_4 * offset.y / offset.x;
        return offset.x * vec2(cos(theta), sin(theta));
	}

	float cos_theta = sin(PI_4 * offset.x / offset.y);
	return offset.y * vec2(cos_theta, sqrt(1.f - cos_theta * cos_theta));
}

vec2 RandomInUnitDisk(inout uvec4 seed)
{
	return concentric_sample_disk( RandomFloat2(seed) );
}

vec3 UniformSampleSphere(vec2 xi)
{
    float z = 1.0 - xi.x - xi.x;
    float phi = TWO_PI * xi.y;
    return vec3(sqrt(max(0.0, 1.0 - z * z)) * vec2(cos(phi), sin(phi)), z);
}

vec3 RandomInUnitSphere(inout uvec4 seed)
{
	return UniformSampleSphere(RandomFloat2(seed));
}

void Onb(vec3 n, out vec3 b1, out vec3 b2) {
	float sign = n.z > 0.f ? 1.f : -1.f;
	float a = -1.f / (sign + n.z);
	b2 = vec3(n.x * n.y * a, sign + n.y * n.y * a, -n.y);
	b1 = vec3(1.f + sign * n.x * n.x * a, sign * b2.x, -sign * n.x);
}

vec3 CosineSampleHemisphere(vec2 xi)
{
    vec3 dir;

    float phi = TWO_PI * xi.y;
    dir.xy = sqrt(xi.x) * vec2(cos(phi), sin(phi));
    dir.z = sqrt(max(0.0, 1.0 - dot(dir.xy, dir.xy)));
    return dir;
}
