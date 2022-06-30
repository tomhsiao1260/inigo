struct Material {
    vec3 color;
};

struct Light {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

float sdSphere( in vec3 p, in float r )
{
    return length(p) - r;
}

float sdSphere1( in vec3 p, in float r, out Material material )
{
    //material.color = abs(vec3(1.0,p.y,p.z))/r*0.25;
    material.color = vec3(1.0, 0.5, 0.0)*0.35;
    return length(p) - r;
}

float sdSphere2( in vec3 p, in float r, out Material material )
{
    //material.color = abs(vec3(p.z,p.y,1.0))/r*0.25;
    material.color = vec3(0.0, 0.5, 1.0)*0.35;
    return length(p) - r;
}

Light lighting( in float id )
{
    Light light;
    
    // nothing
    if (id<0.5) return light;

    if( id<1.5 )
    {
        light.direction = vec3(1.0);
        light.ambient = vec3(1.0,1.0,1.0)*2.0;
        light.diffuse = vec3(0.8,0.7,0.5)*2.0;
        light.specular = vec3(0.8,0.7,0.5)*9.0;
    }

    return light;
}

float map( in vec3 pos, out Material material )
{
    float d = 1e10;
    material.color = vec3(0.0);
    
    float diff = 0.45;
    
    {
        float dd;
        Material materiall;

        vec3 eos = pos;
        eos -= vec3(0.5,0.0,0.0)*(sin(iTime*0.3)+1.0)/2.0;
        //eos -= vec3(diff,0.0,0.0);
        //eos.xz = rot(eos.xz, iTime);

        dd = sdSphere1(eos, 0.3, materiall);
        float aa = smoothstep(-0.2,0.2,d-dd);
        material.color = mix(material.color, materiall.color, aa);

        d = smin(d,dd,0.2);
    }

    {
        float dd;
        Material materiall;

        vec3 eos = pos;
        eos += vec3(0.5,0.0,0.0)*(sin(iTime*0.3)+1.0)/2.0;
        //eos += vec3(diff,0.0,0.0);
        //eos.xz = rot(eos.xz, iTime);
        
        dd = sdSphere2(eos, 0.3, materiall);
        float aa = smoothstep(-0.2,0.2,d-dd);
        material.color = mix(material.color, materiall.color, aa);

        d = smin(d,dd,0.2);
    }

    return d;
}

float mapD( in vec3 pos )
{
    float d = 1e10;
    
    {
        float dd;
        vec3 eos = pos;
        eos -= vec3(0.5,0.0,0.0)*(sin(iTime*0.3)+1.0)/2.0;
        //eos.xz = rot(eos.xz, iTime);
        dd = sdSphere(eos, 0.3);
        d = smin(d,dd,0.2);
    }

    {
        float dd;
        vec3 eos = pos;
        eos += vec3(0.5,0.0,0.0)*(sin(iTime*0.3)+1.0)/2.0;
        //eos.xz = rot(eos.xz, iTime);
        dd = sdSphere(eos, 0.3);
        d = smin(d,dd,0.2);
    }

    return d;
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, float tmin, float tmax, const float k )
{
    float res = 1.0;
    float t = tmin;
    for( int i=0; i<64; i++ )
    {
        float h = mapD( ro + rd*t );
        res = min( res, k*h/t );
        t += clamp( h, 0.003, 0.10 );
        if( res<0.002 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.0005;
    return normalize( e.xyy*mapD( pos + e.xyy*eps ) + 
                      e.yyx*mapD( pos + e.yyx*eps ) + 
                      e.yxy*mapD( pos + e.yxy*eps ) + 
                      e.xxx*mapD( pos + e.xxx*eps ) );
}

#define ZERO (min(iFrame,0))

// Computes SDF convexity, which can be used to approximate ambient occlusion.
// https://iquilezles.org/www/material/nvscene2008/rwwtt.pdf
float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = mapD( pos + h*nor );
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

float intersect( in vec3 ro, in vec3 rd, in float tmax, out Material material )
{
    float t = 0.0;
    
    // raymarch
    for( int i=0; i<256; i++ )
    {
        if( t>tmax ) break;
        vec3 pos = ro + t*rd;
        float d = mapD(pos);
        if( d<0.0001 ) { map(pos, material); break; }
        t += d;
    }

    return t;
}

vec3 render( in vec3 ro, in vec3 rd )
{
    const float tmax = 5.0;
    vec3 color = vec3(0.0);
    Material material;

    float t = intersect( ro, rd, tmax, material );
    
    if( t>tmax ) return color;

    color = material.color;
    
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal(pos);

    float occ = calcOcclusion( pos, nor );
    // get light
    Light light = lighting(1.0);
    {
        vec3 lig = light.direction;
        vec3 hal = normalize( lig-rd );
        float sha = calcSoftshadow( pos, lig, 0.001, 1.0, 64.0 );

        float amb = 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0));
        amb *= occ;

        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        dif *= sha;

        float spe = 1.0 * pow( clamp( dot( nor, hal ), 0.0, 1.0 ), 16.0);
        spe *= 0.04+0.96*pow(clamp(1.0+dot(nor,rd),0.0,1.0), 5.0 );
        spe *= dif;

        color += amb * light.ambient * material.color;
        color += dif * light.diffuse * material.color;
        color += spe * light.specular;
    }

    return color;
}

mat3 calcCamera( out vec3 oRo, out float oFl )
{
    // camera movement  
    float an = 0.1*iTime;
    //vec3 ro = vec3( 1.0*cos(an), 1.0, 1.0*sin(an) );
    vec3 ro = vec3( 0.0, 1.0, 1.0 );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv =          ( cross(uu,ww));
    
    oRo = ro;
    oFl = 1.5;

    return mat3(uu,vv,ww);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    
    vec3 ro; float fl;
    mat3 ca = calcCamera( ro, fl );
    vec3 rd = ca * normalize( vec3(p,fl) );

    vec3 col = render(ro, rd);

    // gamma        
    col = pow(col, vec3(0.4545));

    fragColor = vec4( col, 1.0 );
}