float map( in vec3 pos, inout Material m )
{
    float d = 1e10;
    float e = 0.0001;
    float n = 0.01;
    
    m.ks = 1.0;
    m.se = 16.0;
    m.sss = 0.0;
    m.focc = 1.0;
    m.fsha = 1.0;
    m.color = vec3(0.2,0.3,0.4);

    float d1;
    vec3 m1;
    {
        vec3 p1 = pos-vec3(0.15,0.0,0.0);
        vec4 g1 = sdSphere(p1, 0.2);
        d1 = g1.x;

        if ( m.calc )
        {   
            // color mix
            vec3 color = vec3(0.03,0.03,0.3);

            m.se = 32.0;
            m.sss = 1.0;
            m1 = color;
        }
    }
    m.color = mix(m.color, m1, smoothstep(-0.2,0.2,d-d1));
    d = smin(d, d1, 0.2);
    
    float d2;
    vec3 m2;
    {
        vec3 p2 = pos-vec3(-0.15,0.0,0.0);
        vec4 g2 = sdSphere(p2, 0.2);
        d2 = g2.x;
        float dd2 = d2;

        if ( m.calc )
        {
            // color mix
            vec3 color = vec3(0.03,0.3,0.03);

            m.se = 32.0;
            m.sss = 1.0;
            m2 = color;
        }

        float d21, d211;
        vec3 m21;
        {
            vec3 p21 = p2-vec3(-0.3*cos(iTime),0.3*sin(iTime),0.0);
            vec4 g21 = sdSphere(p21, 0.1);
            d21 = g21.x;

            if ( m.calc )
            {   
                // color mix
                vec3 color = vec3(0.03,0.3,0.3);

                m21 = color;
            }

            {
                //vec3 p211 = p21-vec3(-0.1,0.25,0.0);
                vec3 p211 = p21-vec3(0.1,0.0,0.2);
                vec4 g211 = sdSphere(p211, 0.1);
                d211 = g211.x;

                if ( m.calc )
                {   
                }
            }
            d211 = smin(d21, d211, 0.2);
        }
        m2 = mix(m2, m21, smoothstep(-0.2,0.2,d2-d211));
        d21 = smin(dd2, d21, 0.2);

        //d2 = min(d2, min(d21, d211));
        // fix solution below
        d2 = min(d2, smin(d21, d211, 0.01));

        float d22;
        vec3 m22;
        {
            vec3 p22 = p2-vec3(0.0,0.3,0.0);
            vec4 g22 = sdSphere(p22, 0.1);
            d22 = g22.x;

            if ( m.calc )
            {   
                // color mix
                vec3 color = vec3(0.3,0.0,0.3);

                m22 = color;
            }
            
            float d221;
            vec3 m221;
            {
                vec3 p221 = p22-vec3(0.0,0.2,0.0);
                vec4 g221 = sdSphere(p221, 0.05);
                d221 = g221.x;

                if ( m.calc )
                {   
                    // color mix
                    vec3 color = vec3(0.3,0.0,0.1);

                    m221 = color;
                }
            }
            m22 = mix(m22, m221, smoothstep(-0.2,0.2,d22-d221));
            d22 = smin(d22, d221, 0.2);
        }
        float aa = clamp(d211/dd2,0.0,1.0);
        m2 = mix(m2, m22, smoothstep(-0.2*aa,0.2*aa,d2-d22));
        d22 = smin(dd2, d22, 0.2);
        d2 = min(d2, d22);
    }
    m.color = mix(m.color, m2, smoothstep(-0.2,0.2,d-d2));
    d = smin(d, d2, 0.2);

    return d;
}

