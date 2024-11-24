shader_type canvas_item;

uniform mat4 rotation;
uniform mat4 projection;
uniform mat4 holographic_rotation;
uniform sampler2D rainbow_texture;
uniform sampler2D dissolve_texture : source_color;
uniform float dissolve : hint_range(0,1);
uniform float burn_size: hint_range(0.0, 1.0, 0.01);
uniform vec4 burn_color: source_color;

const float hf_w = 60.0;
const float hf_h = 72.0;

varying vec3 view;

void vertex()
{
	vec4 pos = rotation * vec4(VERTEX.xy - vec2(hf_w, hf_h), 0.0, 1.0);
	float depth = hf_h / 0.267949;
	pos.xyz += vec3(hf_w, hf_h, -depth);
	pos.xyz /= vec3(hf_h);
	pos.xy -= 0.5;
	view = normalize(pos.xyz);
	pos = projection * pos;
	pos /= pos.w;
	pos.xy += 0.5;
	pos.xy *= vec2(hf_h);
	VERTEX = pos.xy;
}

vec2 twirl(vec2 uv, vec2 center, float strength)
{
    vec2 delta = uv - center;
    float angle = strength * length(delta);

    float x = cos(angle) * delta.x - sin(angle) * delta.y;
    float y = sin(angle) * delta.x + cos(angle) * delta.y;

    return vec2(x + center.x, y + center.y);
}

vec4 holographic_effect(vec4 color)
{
	vec3 _view = mat3(rotation) * mat3(holographic_rotation) * view;
	vec2 uv = fract(twirl(_view.xy * 2.0 - 1.0, vec2(0.5, 0.5), 2.0));
	vec4 rainbow = texture(rainbow_texture, uv);
	return vec4(color.rgb + rainbow.rgb * 0.4, color.a);
}

vec4 dissolve_effect(vec4 color, vec2 uv)
{
    vec4 noise_texture = texture(dissolve_texture, uv);
	float burn_size_step = burn_size * step(0.001, dissolve) * step(dissolve, 0.999);
	float threshold = smoothstep(noise_texture.x-burn_size_step, noise_texture.x, dissolve);
	float border = smoothstep(noise_texture.x, noise_texture.x + burn_size_step, dissolve);
	return vec4(mix(burn_color.rgb, color.rgb, border), color.a * threshold);
}

void fragment()
{
	vec4 card = texture(TEXTURE, UV);
	COLOR = holographic_effect(card);
	COLOR = dissolve_effect(COLOR, UV);
}
