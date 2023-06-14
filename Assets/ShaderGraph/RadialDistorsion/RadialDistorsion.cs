using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/RadialDistorsion")]
public sealed class RadialDistorsion : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(5f, 0f, 750f);
    [Tooltip("Controls the radius of the area that is unaffected by the blur.")]
    public ClampedFloatParameter centerRadius = new ClampedFloatParameter(0.5f, 0f, 1f);
   [Tooltip("Moves the center of the distorsion on the X axis")]
    public ClampedFloatParameter centerX = new ClampedFloatParameter(0.5f, 0f, 1f);
   [Tooltip("Moves the center of the distorsion on the Y axis")]
    public ClampedFloatParameter centerY = new ClampedFloatParameter(0.5f, 0f, 1f);
    [Tooltip("Strength of the ray distorsion")]
    public ClampedFloatParameter raysStrenght = new ClampedFloatParameter(0.5f, 0f, 1f);
    [Tooltip("Number of rays")]
    public ClampedIntParameter raysNumber = new ClampedIntParameter(50, 1, 500);
    [Tooltip("Blur size")]
    public ClampedIntParameter blurSize = new ClampedIntParameter(8, 1, 64);
    [Tooltip("Shows the distorsion area.")]
    public BoolParameter isDebug = new BoolParameter(false);

    Material m_Material;

    public bool IsActive() => m_Material != null && intensity.value > 0f;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > Graphics > HDRP Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Shader/RadialDistorsion";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume RadilaDistorsion is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Intensity", intensity.value);
        m_Material.SetFloat("_Radius", centerRadius.value);
        m_Material.SetFloat("_CenterX", centerX.value);
        m_Material.SetFloat("_CenterY", centerY.value);
        m_Material.SetFloat("_RaysStrength", raysStrenght.value);
        m_Material.SetInt("_RaysNumber", raysNumber.value);
        m_Material.SetInt("_Samples", blurSize.value);
        m_Material.SetInt("_IsDebug", isDebug.value ? 1 : 0);
        m_Material.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
