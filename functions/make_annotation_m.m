function [docNode] = make_annotation_m(obj)

    %make base file
    docNode = com.mathworks.xml.XMLUtils.createDocument('annotation');
    annotation = docNode.getDocumentElement;

    %make basic information
    folder = docNode.createElement('folder');
    folder.appendChild(docNode.createTextNode('Grains'));
    annotation.appendChild(folder);

    filename = docNode.createElement('filename');
    filename.appendChild(docNode.createTextNode(strcat(obj.im_name, obj.im_ext)));
    annotation.appendChild(filename);
    
    path = docNode.createElement('path');
    path.appendChild(docNode.createTextNode(strcat(obj.im_name, obj.im_ext)));
    annotation.appendChild(path);
    
    source = docNode.createElement('source');
    database = docNode.createElement('database');
    database.appendChild(docNode.createTextNode('Rgrains'));
    source.appendChild(database);
    annotation.appendChild(source);
    
    isize = docNode.createElement('size');
    wsize = docNode.createElement('width');
    hsize = docNode.createElement('height');
    dsize = docNode.createElement('depth');
    wsize.appendChild(docNode.createTextNode(num2str(size(obj.im_in,1))));
    hsize.appendChild(docNode.createTextNode(num2str(size(obj.im_in,2))));
    dsize.appendChild(docNode.createTextNode(num2str(size(obj.im_in,3))));
    isize.appendChild(wsize);
    isize.appendChild(hsize);
    isize.appendChild(dsize);
    annotation.appendChild(isize);
    
    seg = docNode.createElement('segmented');
    seg.appendChild(docNode.createTextNode('1'));
    annotation.appendChild(seg);
    
    %main descriptions
    %write data
    for ob = 1:length(obj.rprops)

        cur_node0  = docNode.createElement('object');
        cur_node01 = docNode.createElement('name');

        val = obj.opts_export.annotation_target;
        if isfield(obj.rprops(ob), obj.opts_export.annotation_target)
            if ~isempty(obj.rprops(ob).(obj.opts_export.annotation_target))
                val = num2str(obj.rprops(ob).(obj.opts_export.annotation_target));
            end
        end
        cur_node01.appendChild(docNode.createTextNode(val));
        cur_node0.appendChild(cur_node01);
        
        cur_node02 = docNode.createElement('pose');
        cur_node02.appendChild(docNode.createTextNode('Unspecified'));
        cur_node0.appendChild(cur_node02);
        
        cur_node03 = docNode.createElement('truncated');
        cur_node03.appendChild(docNode.createTextNode('0'));
        cur_node0.appendChild(cur_node03);
        
        cur_node04 = docNode.createElement('difficult');
        cur_node04.appendChild(docNode.createTextNode('0'));
        cur_node0.appendChild(cur_node04);
        
        cur_node05 = docNode.createElement('bndbox');

        cur_node51 = docNode.createElement('xmin');
        cur_node51.appendChild(docNode.createTextNode(num2str(obj.rprops(ob).ROI(1))));
        cur_node05.appendChild(cur_node51);

        cur_node52 = docNode.createElement('ymin');
        cur_node52.appendChild(docNode.createTextNode(num2str(obj.rprops(ob).ROI(2))));
        cur_node05.appendChild(cur_node52);

        cur_node53 = docNode.createElement('xmax');
        cur_node53.appendChild(docNode.createTextNode(num2str(obj.rprops(ob).ROI(1)+obj.rprops(ob).ROI(3))));
        cur_node05.appendChild(cur_node53);

        cur_node54 = docNode.createElement('ymax');
        cur_node54.appendChild(docNode.createTextNode(num2str(obj.rprops(ob).ROI(2)+obj.rprops(ob).ROI(4))));
        cur_node05.appendChild(cur_node54);

        cur_node0.appendChild(cur_node05);
        
        %optional original format
        seg_xy = zeros(1,size(obj.rprops(ob).Edges,1)*2);
        seg_xy(1:2:end) = obj.rprops(ob).Edges(:,1) + obj.rprops(ob).ROI(1);
        seg_xy(2:2:end) = obj.rprops(ob).Edges(:,2) + obj.rprops(ob).ROI(2);
        seg_str = strcat('[',num2str(seg_xy),']');
        
        cur_node55 = docNode.createElement('segmentation');
        cur_node55.appendChild(docNode.createTextNode(seg_str));
        cur_node0.appendChild(cur_node55);

        annotation.appendChild(cur_node0);
    end
end
%save data
%xmlwrite(fullfile(outpath, strcat(outname,'.xml')), docNode);