#extension GL_EXT_control_flow_attributes : require

void pcg4d(inout uvec4 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.w; v.y += v.z * v.x; v.z += v.x * v.y; v.w += v.y * v.z;
    v = v ^ (v >> 16u);
    v.x += v.y * v.w; v.y += v.z * v.x; v.z += v.x * v.y; v.w += v.y * v.z;
}

// Returns a float between 0 and 1
float uint_to_float(uint x) { return uintBitsToFloat(0x3f800000 | (x >> 9)) - 1.0f; }

uvec4 InitRandomSeed(uint val0, uint val1, uint frame_num)
{
	return uvec4(val0, val1, frame_num, 0);
}

float RandomFloat(inout uvec4 v)
{
	pcg4d(v);
	return uint_to_float(v.x);
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
	return concentric_sample_disk( vec2( RandomFloat(seed), RandomFloat(seed) ) );
}

vec3 UniformSampleSphere(float r1, float r2)
{
    float z = 1.0 - 2.0 * r1;
    float r = sqrt(max(0.0, 1.0 - z * z));
    float phi = TWO_PI * r2;
    return vec3(r * cos(phi), r * sin(phi), z);
}

vec3 RandomInUnitSphere(inout uvec4 seed)
{
	return UniformSampleSphere(RandomFloat(seed), RandomFloat(seed));
}

#define ToWorld(T, B, N, v) (mat3((T), (B), (N)) * (v))

void Onb(vec3 n, out vec3 b1, out vec3 b2) {
	float sign = n.z > 0.f ? 1.f : -1.f;
	float a = -1.f / (sign + n.z);
	b2 = vec3(n.x * n.y * a, sign + n.y * n.y * a, -n.y);
	b1 = vec3(1.f + sign * n.x * n.x * a, sign * b2.x, -sign * n.x);
}

vec3 CosineSampleHemisphere(float r1, float r2)
{
    vec3 dir;

    float phi = TWO_PI * r2;
    dir.xy = sqrt(r1) * vec2(cos(phi), sin(phi));
    dir.z = sqrt(max(0.0, 1.0 - dir.x * dir.x - dir.y * dir.y));
    return dir;
}
