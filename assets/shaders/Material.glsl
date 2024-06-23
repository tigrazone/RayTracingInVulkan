#ifndef MATERIALS_GLSL

#define MaterialLambertian		0
#define MaterialMetallic		1
#define MaterialDielectric		2
#define MaterialIsotropic		3
#define MaterialDiffuseLight	4

struct Material
{
	vec4 Diffuse;
	int DiffuseTextureId;
	float Fuzziness;
	float RefractionIndex;
	uint MaterialModel;
};

#define MATERIALS_GLSL
#endif