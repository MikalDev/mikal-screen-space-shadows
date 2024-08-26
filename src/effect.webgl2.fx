#version 300 es

// Sample WebGL 2 shader. This just outputs a green color
// to indicate WebGL 2 is in use. Notice that WebGL 2 shaders
// must be written with '#version 300 es' as the very first line
// (no linebreaks or comments before it!) and have updated syntax.

in mediump vec2 vTex;
out lowp vec4 outColor;

#ifdef GL_FRAGMENT_PRECISION_HIGH
#define highmedp highp
#else
#define highmedp mediump
#endif

precision lowp float;

uniform lowp sampler2D samplerFront;
uniform mediump vec2 srcStart;
uniform mediump vec2 srcEnd;
uniform mediump vec2 srcOriginStart;
uniform mediump vec2 srcOriginEnd;
uniform mediump vec2 layoutStart;
uniform mediump vec2 layoutEnd;
uniform lowp sampler2D samplerBack;
uniform lowp sampler2D samplerDepth;
uniform mediump vec2 destStart;
uniform mediump vec2 destEnd;
uniform highmedp float seconds;
uniform mediump vec2 pixelSize;
uniform mediump float layerScale;
uniform mediump float layerAngle;
uniform mediump float devicePixelRatio;
uniform mediump float zNear;
uniform mediump float zFar;

//<-- UNIFORMS -->

#define EPSILON 0.02
#define DEPTH_REVERSED false

float linearizeDepth(float depthValue) {
    float zNear = 100.;
    float zFar = 10000.;
    return (2.0 * zNear) / (zFar + zNear - depthValue * (zFar - zNear));
}

float depth(vec2 coords)
{
	mediump vec2 n = (coords - srcStart) / (srcEnd - srcStart);
	mediump float depthSample = texture(samplerDepth, mix(destStart, destEnd, n)).r;

	float depth = linearizeDepth(depthSample) * uDepthScale;
    if(DEPTH_REVERSED) {
        return 1. - depth;
    } else {
        return depth;
    }
}

void main(void)
{
	vec2 uv = vTex;
    vec2 mouseuv = vec2(uLightX, uLightY);
    
    // uv.x *= 9.0/16.0;
    // mouseuv.x *= 9.0/16.0;
    
    vec3 colour;
    
    vec3 fragPos = vec3(uv, depth(uv));
    vec3 lightPos = vec3(mouseuv, depth(mouseuv) - uLightZ);
    vec2 dir = normalize(fragPos.xy - lightPos.xy);
	vec4 diffuse = texture(samplerFront, uv);
    
    float traverse_by = uStepScale / float(uSamples);
    for(float i = 0.; i < 1.*uStepScale; i += traverse_by) {
        vec3 traversedPos = fragPos + (lightPos - fragPos) * i;
        float traversedDepth = depth(traversedPos.xy);
        
        float diff = traversedPos.z - traversedDepth;
        if(diff > EPSILON) {
            colour += vec3(diff) * traverse_by / uSoftShadow;
        }
    }
    
    colour *= uShadowIntensity;
    vec3 shadow = 1. - colour;
    outColor.rgb = shadow * diffuse.rgb;
    outColor.a = diffuse.a;
}