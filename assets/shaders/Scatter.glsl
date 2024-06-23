#extension GL_EXT_nonuniform_qualifier : require

#include "Random.glsl"
#include "RayPayload.glsl"

float pow5(float x) { return x*x*x*x*x; }

#define ToWorld(T, B, N, v) (mat3((T), (B), (N)) * (v))
#define sum_is_not_empty_abs(a) (abs((a).x) + abs((a).y) + abs((a).z) >= NEARzero)

// Polynomial approximation by Christophe Schlick
float Schlick(const float cosine, const float refractionIndex)
{
	float r0 = (1 - refractionIndex) / (1 + refractionIndex);
	r0 *= r0;
	return r0 + (1 - r0) * pow5(1 - cosine);
}

// Lambertian
RayPayload ScatterLambertian(const Material m, const vec3 direction, const vec3 normal, const vec2 texCoord, const float t, inout uvec4 seed, uint MaterialIndex)
{
	const bool isScattered = dot(direction, normal) < 0;
	const vec4 texColor = m.DiffuseTextureId >= 0 ? texture(TextureSamplers[nonuniformEXT(m.DiffuseTextureId)], texCoord) : vec4(1);
	const vec4 colorAndDistance = vec4(m.Diffuse.rgb * texColor.rgb, t);

	if(isScattered) {
		vec3 T, B;
		Onb(normal, T, B);
		vec3 L = CosineSampleHemisphere(RandomFloat2(seed));

		return RayPayload(colorAndDistance, vec4(ToWorld(T, B, normal, L), 1), seed, MaterialIndex, isScattered);
	}

	return RayPayload(colorAndDistance, vec4(0), seed, MaterialIndex, isScattered);
}

// Metallic
RayPayload ScatterMetallic(const Material m, const vec3 direction, const vec3 normal, const vec2 texCoord, const float t, inout uvec4 seed, uint MaterialIndex)
{
	const bool isScattered = dot(direction, normal) < 0;

	const vec4 texColor = m.DiffuseTextureId >= 0 ? texture(TextureSamplers[nonuniformEXT(m.DiffuseTextureId)], texCoord) : vec4(1);
	const vec4 colorAndDistance = vec4(m.Diffuse.rgb * texColor.rgb, t);

	if(isScattered) {
		return RayPayload(colorAndDistance, vec4(reflect(direction, normal) + m.Fuzziness*RandomInUnitSphere(seed), 1), seed, MaterialIndex, isScattered);
	}

	return RayPayload(colorAndDistance, vec4(0), seed, MaterialIndex, isScattered);
}

// Dielectric
RayPayload ScatterDieletric(const Material m, const vec3 direction, const vec3 normal, const vec2 texCoord, const float t, inout uvec4 seed, uint MaterialIndex)
{
	const float dotDirN = dot(direction, normal);
	const vec3 outwardNormal = dotDirN > 0.f ? -normal : normal;
	const float niOverNt = dotDirN > 0.f ? m.RefractionIndex : 1 / m.RefractionIndex;
	const float cosine = dotDirN > 0.f ? m.RefractionIndex * dotDirN : -dotDirN;

	const vec3 refracted = refract(direction, outwardNormal, niOverNt);
	const float reflectProb = sum_is_not_empty_abs(refracted) ? Schlick(cosine, m.RefractionIndex) : 1;

	const vec4 texColor = m.DiffuseTextureId >= 0 ? texture(TextureSamplers[nonuniformEXT(m.DiffuseTextureId)], texCoord) : vec4(1);
	
	if(RandomFloat(seed) < reflectProb) {
		return RayPayload(vec4(texColor.rgb, t), vec4(reflect(direction, normal), 1), seed, MaterialIndex, dotDirN > 0.f);
	}

	return RayPayload(vec4(texColor.rgb, t), vec4(refracted, 1), seed, MaterialIndex, dotDirN > 0.f);
}

// Diffuse Light
RayPayload ScatterDiffuseLight(const Material m, const float t, inout uvec4 seed, uint MaterialIndex)
{
	const vec4 colorAndDistance = vec4(m.Diffuse.rgb, t);
	const vec4 scatter = vec4(1, 0, 0, 0);

	return RayPayload(colorAndDistance, scatter, seed, MaterialIndex, false);
}

RayPayload Scatter(const Material m, const vec3 direction, const vec3 normal, const vec2 texCoord, const float t, inout uvec4 seed, uint MaterialIndex)
{
	const vec3 normDirection = normalize(direction);

	switch (m.MaterialModel)
	{
	case MaterialLambertian:
		return ScatterLambertian(m, normDirection, normal, texCoord, t, seed, MaterialIndex);
	case MaterialMetallic:
		return ScatterMetallic(m, normDirection, normal, texCoord, t, seed, MaterialIndex);
	case MaterialDielectric:
		return ScatterDieletric(m, normDirection, normal, texCoord, t, seed, MaterialIndex);
	case MaterialDiffuseLight:
		return ScatterDiffuseLight(m, t, seed, MaterialIndex);
	}
}

