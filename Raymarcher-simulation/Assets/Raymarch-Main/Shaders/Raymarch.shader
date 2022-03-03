Shader "Unlit/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define MAX_STEPS 400
            #define MAX_DIST 500
            #define SURF_DIST 1e-3

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }
            float GetDist(float3 w)
            {
                
                //float d = length(p) - .5;
                //d = length(float2(length(p.xz) - .5, p.y)) - .1;
                //float3 q = abs(p) - .5;
                //return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - .1;
                // extract polar coordinates
                float wr = sqrt(dot(w,w));
                float wo = acos(w.y/wr);
                float wi = atan2(w.x,w.z);

                // scale and rotate the point
                wr = pow( wr, 8.0 );
                wo = wo * 8.0;
                wi = wi * 8.0;

                // convert back to cartesian coordinates
                w.x = wr * sin(wo)*sin(wi);
                w.y = wr * cos(wo);
                w.z = wr * sin(wo)*cos(wi);

                return w / 1;
            }
            float mandelbulb (float3 pos, in float n)
            {
                float3 z = pos;
                float dr = 1.;
                float r = .1;
                
                
                
                // from cartesian to polar
                float theta = acos (z.z / r);
                float phi = atan2(z.y, z.x);
                dr = pow(r, n - 1.) * n * dr + 1.;
                
                // scale and rotate the point
                float zr = pow (r, n);
                theta = theta * n;
                phi = phi * n;
                
                // back to cartesian
                z = zr * float3(sin(theta)*cos(phi), sin(theta)*sin(phi), cos(theta));
                z += pos;
                return .5 * log (r) * r / dr; // I just don't get this distance estimator here
            }

            

            float Raymarch(float3 ro, float3 rd)
            {
                float dO = 0;
                float dS;
                for(int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = ro + dO * rd;
                    dS = GetDist(p);
                    dO += dS;
                    if(dS < SURF_DIST || dO > MAX_DIST) break;
                }
                return dO;
            }

            float3 GetNormal(float3 p)
            {
                float2 e = float2(1e-2,0);
                float3 n = GetDist(p) - float3(
                GetDist(p - e.xyy),
                GetDist(p - e.yxy),
                GetDist(p - e.yyx)
                );
                return normalize(n);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - .5;
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);
                float d = Raymarch(ro,rd);

                fixed4 col = 0;
                //col.rgb = rd;
                if(d < MAX_DIST)
                {
                    float3 p = ro + rd * d;
                    float3 n = mandelbulb(p,8);
                    col.rgb = n;
                }
                else
                discard;
                // sample the texture
                
                
                return col;
            }
            ENDCG
        }
    }
}
