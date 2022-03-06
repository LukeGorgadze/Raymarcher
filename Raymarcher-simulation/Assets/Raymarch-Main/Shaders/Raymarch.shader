Shader "Unlit/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MandelColor ("MandelColor", Color) = (1, 1, 1, 1)
        _BackgroundColor ("BackgroundColor", Color) = (1, 1, 1, 1)
        [PowerSlider(10.0)] _Power ("Power", Range (0.01, 20)) = 1.0

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

            #define MAX_STEPS 200
            #define MIN_DIST .001
            #define MAX_DIST 30.
            #define PRECISION .0008

            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MandelColor;
            float4 _BackgroundColor;
            float _Power;
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


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            float3x3 rotateX(float theta){
                float c=cos(theta);
                float s=sin(theta);
                return float3x3(
                float3(1,0,0),
                float3(0,c,-s),
                float3(0,s,c)
                );
            }

            float3x3 rotateY(float theta){
                float c=cos(theta);
                float s=sin(theta);
                return float3x3(
                float3(c,0,s),
                float3(0,1,0),
                float3(-s,0,c)
                );
            }

            // Rotation matrix around the Z axis.
            float3x3 rotateZ(float theta){
                float c=cos(theta);
                float s=sin(theta);
                return float3x3(
                float3(c,-s,0),
                float3(s,c,0),
                float3(0,0,1)
                );
            }

            float3x3 identity(){
                return float3x3(
                float3(1,0,0),
                float3(0,1,0),
                float3(0,0,1)
                );
            }
            float sdSphere(float3 p,float r)
            {
                float3 offset=float3(0,0,-2);
                return length(p-offset)-r;
            }
            float mandelBulb(float3 p,float3x3 transform)
            {
                float3 w = mul(transform,p);
                float m=dot(w,w);
                
                float4 trap=float4(abs(w),m);
                float dz=2.9;
                float power=8.;
                
                for(int i=0;i<4;i++)
                {
                    // dz = 8*z^7*dz
                    dz=power*pow(m,3.5)*dz + 1.9;
                    
                    // z = z^8+z
                    float r=length(w);
                    // rotateX(w);
                    float b=_Power*acos(w.y/r)+_Time.y;
                    float a=_Power*atan2(w.x,w.z) + _Time.y;
                    w=p+pow(r,power)*float3(sin(b)*sin(a),cos(b),sin(b)*cos(a));
                    //w *= abs(sin(b)*cos(a)*log(2. * abs(cos(a))))+.8;
                    //w *= abs(tan(a) * sin(a) * abs(sin(a))) * .4 * abs(sin(a)) * sin(cos(b)) * abs(cos(a)) + .6;
                    //w = mod(u_time,w.x);
                    trap=min(trap,float4(abs(w),m));
                    
                    m=dot(w,w) ;
                    if(m>256.)
                    break;
                }
                // distance estimation (through the Hubbard-Douady potential)
                return .025*log(m)*sqrt(m)/dz * 5;
            }

            

            float Raymarch(float3 ro, float3 rd)
            {
                float depth=.2;
                int iteration = 0;
                
                for(int i=0;i<MAX_STEPS;i++){
                    iteration = i;
                    float3 p=ro+depth*rd;
                    //float d=sdSphere(p,1.);
                    float d=mandelBulb(p,mul(mul(rotateX(90),rotateY(_Time.y/10.)),identity()));
                    depth+=d;
                    if(d<PRECISION||depth>MAX_DIST)break;
                }
                
                return float2(depth,iteration);
            }

            float3 calcNormal(float3 p)
            {
                float2 e=float2(2.,2.)*.000001;// epsilon
                float r=1.;// radius of sphere
                return normalize(
                e.xyy*mandelBulb(p+e.xxx,identity())+
                e.yyx*mandelBulb(p+e.xxx,identity())+
                e.yxy*mandelBulb(p+e.xxx,identity())+
                e.xxx*mandelBulb(p+e.xxx,identity()));
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - .5;

                uv *= float2(2.,2.);
                float3 ro = float3(0,0,3);
                float3 rd = normalize(float3(uv.xy, -1));

                float2 rmComponents = Raymarch(ro,rd);
                float d = rmComponents.x;
                float ite = float(rmComponents.y);

                float multiplier = ite /MAX_STEPS;

                float3 col = tex2D(_MainTex,i.uv);
                
                if(d>MAX_DIST){
                    col=_BackgroundColor * multiplier * 5;// ray didn't hit anything
                }
                else{
                    float3 p=ro+rd*d;// point on sphere we discovered from ray marching
                    float3 normal=calcNormal(p-rd);
                    float3 lightPosition=float3(1.,.5,2.2);
                    float3 lightDirection=normalize(lightPosition-p);
                    
                    // Calculate diffuse reflection by taking the dot product of
                    // the normal and the light direction.
                    float dif=clamp(dot(normal,lightDirection),0.,1.);
                    //shadow
                    float3 newRayOrigin=p;
                    float shadowRayLength=Raymarch(newRayOrigin,lightDirection).x;// cast shadow ray to the light source
                    if(shadowRayLength<length(lightPosition-newRayOrigin))dif*=.8;// if the shadow ray hits the sphere, set the diffuse reflection to zero, simulating a shadow
                    col=float3(dif.xxx)*_MandelColor*pow(.1 - d,4.) *  multiplier * 3;
                }
                
                return float4(col.xyz,1);
            }
            ENDCG
        }
    }
}
