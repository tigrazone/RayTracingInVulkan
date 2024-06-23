#version 460
#extension GL_EXT_nonuniform_qualifier : require
#extension GL_GOOGLE_include_directive : require
#extension GL_EXT_ray_tracing : require
#include "Material.glsl"

layout(binding = 4) readonly buffer VertexArray { float Vertices[]; };
layout(binding = 5) readonly buffer IndexArray { uint Indices[]; };
layout(binding = 6) readonly buffer MaterialArray { Material[] Materials; };
layout(binding = 7) readonly buffer OffsetArray { uvec2[] Offsets; };
layout(binding = 8) uniform sampler2D[] TextureSamplers;

#include "Scatter.glsl"
#include "Vertex.glsl"

hitAttributeEXT vec2 HitAttributes;
rayPayloadInEXT RayPayload Ray;

#define Mix(a, b, c, barycentrics) ( (a) * (barycentrics).x + (b) * (barycentrics).y + (c) * (barycentrics).z )

void main()
{
	// Get the material.
	const uvec2 offsets = Offsets[gl_InstanceCustomIndexEXT];
	const uint indexOffset = offsets.x + gl_PrimitiveID * 3;
	const uint vertexOffset = offsets.y;
	const Vertex v0 = UnpackVertex(vertexOffset + Indices[indexOffset]);
	const Vertex v1 = UnpackVertex(vertexOffset + Indices[indexOffset + 1]);
	const Vertex v2 = UnpackVertex(vertexOffset + Indices[indexOffset + 2]);
	const Material material = Materials[v0.MaterialIndex];

	// Compute the ray hit point properties.
	const vec3 barycentrics = vec3(1.0 - HitAttributes.x - HitAttributes.y, HitAttributes.x, HitAttributes.y);

	Ray = Scatter(material, gl_WorldRayDirectionEXT, 
				  normalize(ToWorld(v0.Normal, v1.Normal, v2.Normal, barycentrics)), 
				  Mix(v0.TexCoord, v1.TexCoord, v2.TexCoord, barycentrics), 
				  gl_HitTEXT, Ray.RandomSeed, v0.MaterialIndex);
}
